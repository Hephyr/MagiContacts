//
//  PhoneticContacts.swift
//  MagiContacts
//
//  Created by Hefeng Xu on 7/29/23.
//

import Foundation
import Contacts
import ContactsUI

struct Contact {
    var cnContact: CNMutableContact
    var isSelected: Bool = true
}

class ContactManager: ObservableObject {
    private let store = CNContactStore()
    
    @Published var contacts: [Contact] = []
    
    init() {
        
    }
    
    func checkPermission() -> Bool {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            return true
        default:
            return false
        }
    }
    
    func requestAccess(completion: @escaping (Bool) -> Void) {
        store.requestAccess(for: .contacts) { granted, error in
            completion(granted)
        }
    }
    
    public func updatePhoneticNames() {
        contacts.removeAll()
        let request = CNContactFetchRequest(keysToFetch: [CNContactGivenNameKey as CNKeyDescriptor, CNContactFamilyNameKey as CNKeyDescriptor, CNContactIdentifierKey as CNKeyDescriptor, CNContactPhoneticGivenNameKey as CNKeyDescriptor, CNContactPhoneticFamilyNameKey as CNKeyDescriptor])
        
        do {
            try store.enumerateContacts(with: request) { (contact, stopPointer) in
                let mutableContact = contact.mutableCopy() as! CNMutableContact
                let removeToneMarks = UserDefaults.standard.bool(forKey: "removeToneMarks")
                var needSave = false
                if (/*contact.phoneticGivenName.isEmpty && */containsChineseCharacters(contact.givenName)) {
                    needSave = true
                    mutableContact.phoneticGivenName = transformToLatin(input: contact.givenName)
                    if (removeToneMarks) {
                        mutableContact.phoneticGivenName = stripCombiningMarks(input: mutableContact.phoneticGivenName)
                    }
                }
                if (/*contact.phoneticFamilyName.isEmpty && */containsChineseCharacters(contact.familyName)) {
                    needSave = true
                    mutableContact.phoneticFamilyName = transFamilyNameToLatin(lastName: contact.familyName)
                    if (removeToneMarks) {
                        mutableContact.phoneticFamilyName = stripCombiningMarks(input: mutableContact.phoneticFamilyName)
                    }
                }
                if needSave {
                    let c = Contact(cnContact: mutableContact)
                    self.contacts.append(c)
                }
            }
        } catch {
            print("Failed to fetch contacts.")
        }
    }
    
    public func save() {
        for contact in self.contacts.filter({$0.isSelected}) {
            let saveRequest = CNSaveRequest()
            saveRequest.update(contact.cnContact)
            try? self.store.execute(saveRequest)
        }
    }
    
    public func clear() {
        self.contacts.removeAll()
    }
    
    private func transFamilyNameToLatin(lastName: String) -> String {
        let specialLastName: [String: String] = [
            "柏": "bǎi",
            "鲍": "bào",
            "贲": "bēn",
            "秘": "bì",
            "薄": "bó",
            "卜": "bǔ",
            "岑": "cén",
            "晁": "cháo",
            "谌": "chén",
            "种": "chóng",
            "褚": "chǔ",
            "啜": "chuài",
            "单": "shàn",
            "郗": "xī",
            "邸": "dǐ",
            "都": "dū",
            "缪": "miào",
            "宓": "mì",
            "费": "fèi",
            "苻": "fú",
            "睢": "suī",
            "区": "ōu",
            "华": "huà",
            "庞": "páng",
            "查": "zhā",
            "佘": "shé",
            "仇": "qiú",
            "靳": "jìn",
            "解": "xiè",
            "繁": "pó",
            "折": "shé",
            "员": "yùn",
            "祭": "zhài",
            "芮": "ruì",
            "覃": "qín", // 多个音都有
            "牟": "móu", // 多个音都有
            "蕃": "pó",
            "戚": "qī",
            "瞿": "qú",
            "冼": "xiǎn",
            "洗": "xiǎn",
            "郤": "xì",
            "庹": "tuǒ",
            "彤": "tóng",
            "佟": "tóng",
            "妫": "guī",
            "句": "gōu",
            "郝": "hǎo",
            "曾": "zēng",
            "乐": "yuè",
            "蔺": "lìn",
            "隽": "juàn",
            "臧": "zāng",
            "庾": "yǔ",
            "詹": "zhān",
            "禚": "zhuó",
            "迮": "zé",
            "沈": "shěn",
            "沉": "shěn",
            "尉": "yù",
            "尉迟": "yùchí",
            "长孙": "zhǎngsūn",
            "中行": "zhōngháng",
            "万俟": "mòqí",
            "单于": "chányú"
        ]
        if let r = specialLastName[lastName] {
            return r
        } else {
            return transformToLatin(input: lastName)
        }
    }
    
    private func transformToLatin(input: String) -> String {
        let mutableString = NSMutableString(string: input) as CFMutableString
        CFStringTransform(mutableString, nil, kCFStringTransformMandarinLatin, false)
        return mutableString as String
    }
    
    private func stripCombiningMarks(input: String) -> String {
        let mutableString = NSMutableString(string: input) as CFMutableString
        CFStringTransform(mutableString, nil, kCFStringTransformStripCombiningMarks, false)
        return mutableString as String
    }
    
    private func containsChineseCharacters(_ string: String) -> Bool {
        for scalar in string.unicodeScalars {
            if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF {
                return true
            }
        }
        return false
    }
}
