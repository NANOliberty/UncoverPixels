//
//  PixelTextField.swift
//  UncoverYourPixels
//
//  앱 공통 입력 필드.
//

import SwiftUI

struct PixelTextField: View {
    let placeholder: String
    @Binding var text: String
    var isFocused: Bool = false
    var alignment: TextAlignment = .leading
    var limit: Int? = nil
    var submitLabel: SubmitLabel = .done

    var body: some View {
        TextField("", text: $text, prompt: Text(placeholder)
            .font(AppFont.body)
            .foregroundColor(DTheme.purpleDark))
            .font(AppFont.body)
            .foregroundColor(DTheme.textSoft)
            .multilineTextAlignment(alignment)
            .autocorrectionDisabled()
            .textInputAutocapitalization(.never)
            .submitLabel(submitLabel)
            .accentColor(DTheme.purpleLight)
            .padding(.horizontal, AppSpacing.lg)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 2).fill(DTheme.cardBg))
            .overlay(RoundedRectangle(cornerRadius: 2)
                .stroke(isFocused ? DTheme.purpleLight : DTheme.cardEdge, lineWidth: 1.5))
            .onChange(of: text) { _, new in
                if let limit, new.count > limit { text = String(new.prefix(limit)) }
            }
    }
}

#Preview("PixelTextField") {
    @Previewable @State var empty = ""
    @Previewable @State var filled = "나노"
    return ZStack {
        AuroraBackground()
        VStack(spacing: 16) {
            PixelTextField(placeholder: "닉네임을 입력해주세요", text: $empty, alignment: .center)
            PixelTextField(placeholder: "닉네임을 입력해주세요", text: $filled, isFocused: true, alignment: .center)
        }
        .padding(32)
    }
}
