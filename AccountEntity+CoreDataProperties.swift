import Foundation
import CoreData


extension AccountEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<AccountEntity> {
        return NSFetchRequest<AccountEntity>(entityName: "AccountEntity")
    }

    @NSManaged public var connectedAt: Date?
    @NSManaged public var displayName: String?
    @NSManaged public var email: String?
    @NSManaged public var isConnected: Bool
    @NSManaged public var provider: String?

}
