import Foundation
import UIKit
import AppAuth

// MARK: - Service

final class GoogleAuthService: NSObject, ObservableObject {
    static let shared = GoogleAuthService()
    
    // OAuth config
    private let issuer = URL(string: "https://accounts.google.com")!
    private let clientID = "754952121691-s1v26sd45geh1mh7lqhtjnh5bskfmggc.apps.googleusercontent.com"
    private let redirectURI = URL(string: "com.googleusercontent.apps.754952121691-s1v26sd45geh1mh7lqhtjnh5bskfmggc:/oauthredirect")!
    
    // Scopes
    private let calendarScope = "https://www.googleapis.com/auth/calendar.readonly"
    
    @Published private(set) var authState: OIDAuthState?
    private var currentAuthorizationFlow: OIDExternalUserAgentSession?
    private let storeKey = "google_auth_state"
    
    override init() {
        super.init()
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let state = try? NSKeyedUnarchiver.unarchivedObject(ofClass: OIDAuthState.self, from: data) {
            self.authState = state
        }
    }
    
    private func normEmail(_ e: String?) -> String? { e?.lowercased() }

    
    // MARK: Sign in / resume
    
    func signIn(presenting viewController: UIViewController) async throws {
        let config = try await OIDAuthorizationService.discoverConfiguration(forIssuer: issuer)
        let request = OIDAuthorizationRequest(
            configuration: config,
            clientId: clientID,
            clientSecret: nil,
            scopes: [OIDScopeOpenID, OIDScopeProfile, OIDScopeEmail, calendarScope],
            redirectURL: redirectURI,
            responseType: OIDResponseTypeCode,
            additionalParameters: [
                "prompt": "consent select_account",
                "access_type": "offline"
            ]
        )
        
        try await withCheckedThrowingContinuation { cont in
            self.currentAuthorizationFlow =
            OIDAuthState.authState(byPresenting: request, presenting: viewController) { state, error in
                if let state {
                    self.setAuthState(state)
                    cont.resume()
                } else {
                    cont.resume(throwing: error ?? NSError(domain: "Auth", code: -1))
                }
            }
        }
    }
    
    @discardableResult
    func resume(_ url: URL) -> Bool {
        if let flow = currentAuthorizationFlow,
           flow.resumeExternalUserAgentFlow(with: url) {
            currentAuthorizationFlow = nil
            return true
        }
        return false
    }
    
    func signOut() {
        authState = nil
        UserDefaults.standard.removeObject(forKey: storeKey)
    }
    
    private func setAuthState(_ state: OIDAuthState) {
        authState = state
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: state, requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: storeKey)
        }
    }
    
    // MARK: Tokens
    
    func getAccessToken(_ completion: @escaping (String?) -> Void) {
        authState?.performAction { accessToken, _, error in
            if let error { print("Token error:", error) }
            completion(accessToken)
        }
    }
    
    func fetchSignedInEmail(_ completion: @escaping (String?) -> Void) {
        if let idToken = authState?.lastTokenResponse?.idToken,
           let claims = JWT.decodeClaims(idToken),
           let email = claims["email"] as? String {
            completion(email.lowercased())
            return
        }
        getAccessToken { token in
            guard let token = token else { completion(nil); return }
            var req = URLRequest(url: URL(string: "https://www.googleapis.com/oauth2/v3/userinfo")!)
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            URLSession.shared.dataTask(with: req) { data, _, _ in
                guard let data,
                      let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let email = obj["email"] as? String else { completion(nil); return }
                completion(email.lowercased())
            }.resume()
        }
    }

    func fetchGoogleEventsRangePaged(
        timeMin: Date,
        timeMax: Date,
        onPage: @escaping (_ accountEmail: String, _ items: [GoogleEvent]) -> Void,
        onComplete: @escaping (_ accountEmail: String, _ total: Int) -> Void
    ) {
        fetchSignedInEmail { email in
            guard let email = email else { return }
            self.rangePage(email: email, timeMin: timeMin, timeMax: timeMax,
                           pageToken: nil, total: 0, onPage: onPage, onComplete: onComplete)
        }
    }

    
    private func rangePage(
        email: String,
        timeMin: Date,
        timeMax: Date,
        pageToken: String?,
        total: Int,
        onPage: @escaping (_ accountEmail: String, _ items: [GoogleEvent]) -> Void,
        onComplete: @escaping (_ accountEmail: String, _ total: Int) -> Void
    ) {
        getAccessToken { token in
            guard let token else { onComplete(email, total); return }
            
            var comps = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
            let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var q: [URLQueryItem] = [
                .init(name: "singleEvents", value: "true"),
                .init(name: "orderBy", value: "startTime"),
                .init(name: "maxResults", value: "2500"),
                .init(name: "timeMin", value: iso.string(from: timeMin)),
                .init(name: "timeMax", value: iso.string(from: timeMax))
            ]
            if let pageToken { q.append(.init(name: "pageToken", value: pageToken)) }
            comps.queryItems = q
            
            var req = URLRequest(url: comps.url!)
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: req) { data, response, error in
                guard error == nil, let data = data else {
                    print("Range page error:", error ?? "")
                    onComplete(email, total)
                    return
                }
                do {
                    let page = try JSONDecoder().decode(GoogleCalendarResponse.self, from: data)
                    let newTotal = total + (page.items.count)
                    if !page.items.isEmpty { onPage(email, page.items) }
                    if let next = page.nextPageToken {
                        self.rangePage(email: email, timeMin: timeMin, timeMax: timeMax, pageToken: next, total: newTotal, onPage: onPage, onComplete: onComplete)
                    } else {
                        onComplete(email, newTotal)
                    }
                } catch {
                    if let http = response as? HTTPURLResponse, let raw = String(data: data, encoding: .utf8) {
                        print("Decode error (\(http.statusCode)):", error, "\nRAW:\n", raw)
                    } else {
                        print("Decode error:", error)
                    }
                    onComplete(email, total)
                }
            }.resume()
        }
    }
    
    // MARK: Convenience – last 3 months / rest of year
    
    func fetchLastThreeMonths(
        onPage: @escaping (_ accountEmail: String, _ items: [GoogleEvent]) -> Void,
        onComplete: @escaping (_ accountEmail: String, _ total: Int) -> Void
    ) {
        let cal = Calendar.current
        let now = Date()
        let start = cal.threeMonthsAgoStart(now)
        fetchGoogleEventsRangePaged(timeMin: start, timeMax: now, onPage: onPage, onComplete: onComplete)
    }
    
    func fetchRestOfYear(
        onPage: @escaping (_ accountEmail: String, _ items: [GoogleEvent]) -> Void,
        onComplete: @escaping (_ accountEmail: String, _ total: Int) -> Void
    ) {
        let cal = Calendar.current
        let now = Date()
        let start = cal.startOfTomorrow(now)
        let end = cal.endOfYear(for: now)
        fetchGoogleEventsRangePaged(timeMin: start, timeMax: end, onPage: onPage, onComplete: onComplete)
    }
    
    // MARK: Delta sync (syncToken)
    
    /// Applies only changes since last sync. Set a syncToken after initial backfill.
    func deltaSync(
        onPage: @escaping (_ accountEmail: String, _ items: [GoogleEvent], _ deletedIDs: [String]) -> Void,
        onComplete: @escaping (_ accountEmail: String, _ total: Int) -> Void
    ) {
        fetchSignedInEmail { email in
            guard let email else { return }
            guard let token = GoogleAccountStore.shared.syncToken(for: email) else {
                print("No syncToken for \(email). Backfill first.")
                onComplete(email, 0); return
            }
            self.deltaPage(email: email, syncToken: token, pageToken: nil, total: 0, onPage: onPage, onComplete: onComplete)
        }
    }
    
    private func deltaPage(
        email: String,
        syncToken: String,
        pageToken: String?,
        total: Int,
        onPage: @escaping (_ accountEmail: String, _ items: [GoogleEvent], _ deletedIDs: [String]) -> Void,
        onComplete: @escaping (_ accountEmail: String, _ total: Int) -> Void
    ) {
        getAccessToken { token in
            guard let token else { onComplete(email, total); return }
            
            var comps = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
            var q: [URLQueryItem] = [
                .init(name: "singleEvents", value: "true"),
                .init(name: "showDeleted", value: "true"),
                .init(name: "maxResults", value: "2500"),
                .init(name: "syncToken", value: syncToken)
            ]
            if let pageToken { q.append(.init(name: "pageToken", value: pageToken)) }
            comps.queryItems = q
            
            var req = URLRequest(url: comps.url!)
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: req) { data, response, error in
                guard error == nil, let data = data else {
                    print("Delta error:", error ?? "")
                    onComplete(email, total)
                    return
                }
                do {
                    let page = try JSONDecoder().decode(GoogleCalendarResponse.self, from: data)
                    
                    // Deleted: look for status == "cancelled"
                    let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
                    let itemsArr = (json?["items"] as? [[String: Any]]) ?? []
                    let deletedIDs = itemsArr.compactMap { dict -> String? in
                        (dict["status"] as? String) == "cancelled" ? (dict["id"] as? String) : nil
                    }
                    
                    onPage(email, page.items, deletedIDs)
                    
                    let newTotal = total + page.items.count
                    if let next = page.nextPageToken {
                        self.deltaPage(email: email, syncToken: syncToken, pageToken: next, total: newTotal, onPage: onPage, onComplete: onComplete)
                    } else {
                        if let nextSync = page.nextSyncToken {
                            GoogleAccountStore.shared.saveSyncToken(nextSync, for: email)
                        }
                        onComplete(email, newTotal)
                    }
                } catch {
                    if let http = response as? HTTPURLResponse, http.statusCode == 410 {
                        // token expired — clear and backfill
                        GoogleAccountStore.shared.removeSyncToken(for: email)
                        print("Sync token expired. Backfill required.")
                    } else {
                        print("Delta decode error:", error)
                        if let raw = String(data: data, encoding: .utf8) { print("RAW:", raw) }
                    }
                    onComplete(email, total)
                }
            }.resume()
        }
    }
    
    // MARK: Mapping to your app model
    
    func mapToCalendarEvents(_ items: [GoogleEvent]) -> [CalendarEvent] {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        print("Calendar items : \(items)")
        return items.compactMap { item in
            guard item.status != "cancelled" else { return nil }
            let s = item.start.dateTime ?? item.start.date
            let e = item.end.dateTime ?? item.end.date
            guard let ss = s, let ee = e else { return nil }
            let start = fmt.date(from: ss) ?? ISO8601DateFormatter().date(from: ss)
            let end   = fmt.date(from: ee) ?? ISO8601DateFormatter().date(from: ee)
            guard let start, let end else { return nil }
            return CalendarEvent(
                title: item.summary ?? "(No Title)",
                location: item.location,
                start: start,
                end: end,
                color: .blue,
                source: .google
            )
        }
    }
    
    func seedSyncToken(completion: @escaping (_ email: String, _ success: Bool) -> Void) {
        guard let accessToken = authState?.lastTokenResponse?.accessToken else {
            completion("", false); return
        }
        fetchUserEmail(with: accessToken) { email in
            guard let email = email?.lowercased() else { completion("", false); return }
            self.seedPage(accessToken: accessToken, pageToken: nil) { syncToken in
                if let token = syncToken {
                    GoogleAccountStore.shared.saveSyncToken(token, for: email)
                    print("✅ Seeded sync token for \(email)")
                    DispatchQueue.main.async { completion(email, true) }
                } else {
                    print("⚠️ Could not seed sync token for \(email)")
                    DispatchQueue.main.async { completion(email, false) }
                }
            }
        }
    }

    private func seedPage(accessToken: String, pageToken: String?, done: @escaping (String?) -> Void) {
        var comps = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
        var items: [URLQueryItem] = [
            .init(name: "singleEvents", value: "true"),
            .init(name: "showDeleted", value: "true"),
            .init(name: "maxResults", value: "2500"),
            // Ask only for tokens to keep payload tiny
            .init(name: "fields", value: "nextPageToken,nextSyncToken")
        ]
        if let pageToken { items.append(.init(name: "pageToken", value: pageToken)) }
        comps.queryItems = items

        var req = URLRequest(url: comps.url!)
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: req) { data, _, err in
            guard err == nil, let data = data,
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                done(nil); return
            }
            if let nextPage = obj["nextPageToken"] as? String {
                self.seedPage(accessToken: accessToken, pageToken: nextPage, done: done)
            } else {
                done(obj["nextSyncToken"] as? String) // only present on final page
            }
        }.resume()
    }

    private func fetchUserEmail(with accessToken: String, completion: @escaping (String?) -> Void) {
        var req = URLRequest(url: URL(string: "https://www.googleapis.com/oauth2/v3/userinfo")!)
        req.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        URLSession.shared.dataTask(with: req) { data, _, _ in
            guard let data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let email = json["email"] as? String else { completion(nil); return }
            completion(email.lowercased())
        }.resume()
    }
    
    // Page through until we get nextSyncToken (only present on the last page).
    private func seedPage(
        email: String,
        pageToken: String?,
        onDone: @escaping (_ nextSyncToken: String?) -> Void
    ) {
        getAccessToken { token in
            guard let token else { onDone(nil); return }
            
            var comps = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
            var q: [URLQueryItem] = [
                .init(name: "singleEvents", value: "true"),
                .init(name: "showDeleted", value: "true"),
                .init(name: "maxResults", value: "2500"),
                // Only fetch tokens to minimize response size.
                .init(name: "fields", value: "nextPageToken,nextSyncToken")
            ]
            if let pageToken { q.append(.init(name: "pageToken", value: pageToken)) }
            comps.queryItems = q
            
            var req = URLRequest(url: comps.url!)
            req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            URLSession.shared.dataTask(with: req) { data, response, error in
                guard error == nil, let data = data else { onDone(nil); return }
                
                // Parse minimal JSON: { nextPageToken?: string, nextSyncToken?: string }
                let obj = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
                let nextSync = obj?["nextSyncToken"] as? String
                let nextPage = obj?["nextPageToken"] as? String
                
                if let nextPage {
                    // keep paging until no nextPageToken
                    self.seedPage(email: email, pageToken: nextPage, onDone: onDone)
                } else {
                    // last page -> we should have nextSyncToken here
                    onDone(nextSync)
                }
            }.resume()
        }
    }
    
}

// MARK: - Back-compat convenience

extension GoogleAuthService {
    /// Prints userinfo JSON and returns (email, json) if needed.
    func fetchUserProfile(completion: ((String?, [String: Any]?) -> Void)? = nil) {
        fetchSignedInEmail { email in
            self.getAccessToken { token in
                guard let token = token else { completion?(email, nil); return }
                var req = URLRequest(url: URL(string: "https://www.googleapis.com/oauth2/v3/userinfo")!)
                req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                URLSession.shared.dataTask(with: req) { data, _, _ in
                    var jsonObj: [String: Any]? = nil
                    if let data,
                       let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        jsonObj = obj
                        print("Google user info:", obj)
                    }
                    completion?(email, jsonObj)
                }.resume()
            }
        }
    }
    
    /// Mapped `[CalendarEvent]`. Defaults to current week if no dates passed.
    func fetchCalendarEvents(
        timeMin: Date? = nil,
        timeMax: Date? = nil,
        completion: @escaping ([CalendarEvent]) -> Void
    ) {
        let cal = Calendar.current
        let start = timeMin ?? cal.date(from: cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        let end   = timeMax ?? cal.date(byAdding: .day, value: 7, to: start)!
        fetchGoogleEventsRangePaged(timeMin: start, timeMax: end) { _, items in
            // accumulate per page; for simplicity map immediately and append
            let mapped = self.mapToCalendarEvents(items)
            DispatchQueue.main.async { completion(mapped) }
        } onComplete: { _, _ in }
    }
}

// MARK: - Adapter (returns AuthUser)

final class GoogleAuthAdapter: AuthService {
    func signIn(presenting vc: UIViewController) async throws -> AuthUser {
        try await GoogleAuthService.shared.signIn(presenting: vc)
        if let idToken = GoogleAuthService.shared.authState?.lastTokenResponse?.idToken,
           let claims = JWT.decodeClaims(idToken) {
            let sub   = (claims["sub"] as? String) ?? UUID().uuidString
            let email = (claims["email"] as? String) ?? "unknown@google"
            return AuthUser(id: sub, email: email, provider: "google")
        }
        let email = await withCheckedContinuation { (cont: CheckedContinuation<String, Never>) in
            GoogleAuthService.shared.fetchSignedInEmail { cont.resume(returning: $0 ?? "unknown@google") }
        }
        return AuthUser(id: UUID().uuidString, email: email, provider: "google")
    }
}

// MARK: - JWT helper

enum JWT {
    static func decodeClaims(_ jwt: String) -> [String: Any]? {
        let parts = jwt.split(separator: ".")
        guard parts.count >= 2,
              let data = Data(base64URL: String(parts[1])) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

private extension Data {
    init?(base64URL: String) {
        var s = base64URL.replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let pad = 4 - (s.count % 4)
        if pad < 4 { s.append(String(repeating: "=", count: pad)) }
        self.init(base64Encoded: s)
    }
}

extension GoogleAuthService {

    func fetchWindow(from: Date, to: Date, completion: @escaping (_ email: String, _ items: [GoogleEvent]) -> Void) {
        fetchSignedInEmail { email in
            guard let email else { completion("unknown", []); return }

            self.getAccessToken { token in
                guard let token else { completion(email, []); return }

                let fmt = ISO8601DateFormatter()
                fmt.timeZone = TimeZone(secondsFromGMT: 0)
                fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

                var comps = URLComponents(string: "https://www.googleapis.com/calendar/v3/calendars/primary/events")!
                comps.queryItems = [
                    .init(name: "singleEvents", value: "true"),
                    .init(name: "orderBy", value: "startTime"),
                    .init(name: "timeMin", value: fmt.string(from: from)),
                    .init(name: "timeMax", value: fmt.string(from: to)),
                    .init(name: "maxResults", value: "2500")
                ]

                var req = URLRequest(url: comps.url!)
                req.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

                URLSession.shared.dataTask(with: req) { data, _, err in
                    guard err == nil, let data = data else {
                        completion(email, []); return
                    }
                    do {
                        let resp = try JSONDecoder().decode(GoogleCalendarResponse.self, from: data)
                        completion(email, resp.items)
                    } catch {
                        print("window decode error:", error)
                        completion(email, [])
                    }
                }.resume()
            }
        }
    }
}
