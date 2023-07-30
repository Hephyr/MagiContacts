//
//  PhoneticContactsView.swift
//  MagiContacts
//
//  Created by Hefeng Xu on 7/29/23.
//

import SwiftUI

struct PhoneticContactsView: View {
    @AppStorage("removeToneMarks") var removeToneMarks: Bool = false
    
    @State private var showingSheet = false
    @State private var showingAlert = false
    
    @StateObject private var contactManager = ContactManager()
    
    var body: some View {
        NavigationView {
            Form {
                Section(footer: Text("remove_tone_marks_description")) {
                    Toggle("remove_tone_marks", isOn: $removeToneMarks)
                }
                Section() {
                    Button(action: {
                        // Call your function here
                        showingSheet = true
                        if !contactManager.checkPermission() {
                            contactManager.requestAccess { granted in
                                if !granted {
                                    showingAlert = true
                                }
                            }
                        } else {
                            contactManager.updatePhoneticNames()
                        }
                    }) {
                        Text("excute")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle()) // Remove the default button style
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
            }
            .navigationTitle("MagiContact")
            .sheet(isPresented: $showingSheet, onDismiss: {contactManager.clear()}) {
                NavigationView {
                    VStack{
                        List {
                            ForEach($contactManager.contacts, id: \.cnContact.identifier) {$contact in
                                HStack {
                                    Image(systemName: contact.isSelected ? "checkmark.circle.fill" : "checkmark.circle")
                                        .foregroundColor(contact.isSelected ? .blue : .gray)
                                    Text("\(contact.cnContact.familyName) \(contact.cnContact.givenName) -> \(contact.cnContact.phoneticFamilyName) \(contact.cnContact.phoneticGivenName)")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    contact.isSelected.toggle()
                                }
                                
                            }
                        }
                        Button(action: {
                            contactManager.save()
                            showingSheet = false
                        }) {
                            Text("保存至通讯录")
                                .padding()
                                .foregroundColor(.blue)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .disabled($contactManager.contacts.isEmpty)
                    }
                    .navigationBarTitle("扫描完成", displayMode: .inline)
                    .navigationBarItems(leading: Button(action: {
                        showingSheet = false
                    }) {
                        Text("取消")
                            .foregroundColor(.blue)
                    })
                }
                
            }
            .alert(isPresented: $showingAlert) {
                Alert(
                    title: Text("Access Denied"),
                    message: Text("This feature requires access to your contacts."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
}

struct PhoneticContactsView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneticContactsView()
    }
}
