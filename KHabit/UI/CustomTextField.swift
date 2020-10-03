//
//  CustomTextField.swift
//  KHabit
//
//  Created by Stefano Bertoli on 01/10/20.
//  Copyright © 2020 elkiwy. All rights reserved.
//

import SwiftUI

struct CustomTextField: UIViewRepresentable {
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var isResponder : Bool?
                
        init(text: Binding<String>, isResponder : Binding<Bool?>) {
            print("init")
            _text = text
            _isResponder = isResponder
        }
        
        func textFieldDidChangeSelection(_ textField: UITextField) {
            print("textfielddidchangeselection")
            if self.isResponder ?? false{
                text = textField.text ?? ""
            }
        }
        
        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            print("textfieldshulretunr")
            textField.resignFirstResponder()
            self.isResponder = false
            return true
        }
    }
    
    @Binding var text: String
    @Binding var isResponder : Bool?

    func makeUIView(context: UIViewRepresentableContext<CustomTextField>) -> UITextField {
        print("make uiView")
        let textField = UITextField(frame: .zero)
        textField.keyboardType = .default
        textField.delegate = context.coordinator
        textField.returnKeyType = .done
        return textField
    }
    
    func makeCoordinator() -> CustomTextField.Coordinator {
        print("makeCorrdinator")
        return Coordinator(text: $text, isResponder: $isResponder)
    }
    
    func updateUIView(_ uiView: UITextField, context: UIViewRepresentableContext<CustomTextField>) {
        print("make updateUIVIew")
        uiView.text = text
        if isResponder ?? false {
            uiView.becomeFirstResponder()
        }
    }
    
}
