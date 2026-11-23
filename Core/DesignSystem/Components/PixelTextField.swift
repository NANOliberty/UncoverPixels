//
//  PixelTextField.swift
//  UncoverYourPixels
//
//  앱 공통 입력 필드. 닉네임, 작품 이름, 한 줄 일기, 검색이 모두 이것을 쓴다.
//

import SwiftUI

struct PixelTextField: View {
    /// 보통 크기와, 검색창처럼 한 줄에 끼워 넣는 작은 크기
    enum Size {
        case regular, compact

        var font: Font { self == .regular ? AppFont.body : AppFont.label }
        var verticalPadding: CGFloat { self == .regular ? AppSpacing.lg : AppSpacing.sm }
        var iconSize: CGFloat { self == .regular ? 14 : 12 }
    }

    let placeholder: String
    @Binding var text: String
    var isFocused: Bool = false
    var alignment: TextAlignment = .leading
    var limit: Int? = nil
    var submitLabel: SubmitLabel = .done
    var size: Size = .regular
    /// 왼쪽에 붙는 SF 심볼 이름 (검색창의 돋보기 등)
    var icon: String? = nil
    /// 글자가 있을 때 오른쪽에 나오는 지우기 단추
    var showsClearButton: Bool = false

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: size.iconSize))
                    .foregroundColor(DTheme.textDim)
            }

            TextField("", text: $text, prompt: Text(placeholder)
                .font(size.font)
                .foregroundColor(DTheme.purpleDark))
                .font(size.font)
                .foregroundColor(.white)
                .multilineTextAlignment(alignment)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .submitLabel(submitLabel)
                .accentColor(DTheme.purpleLight)
                .onChange(of: text) { _, new in
                    if let limit, new.count > limit { text = String(new.prefix(limit)) }
                }

            if showsClearButton, !text.isEmpty {
                Button { text = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: size.iconSize))
                        .foregroundColor(DTheme.textDim)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, size.verticalPadding)
        .background(DTheme.surface)
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md)
            .stroke(isFocused ? DTheme.purpleLight : DTheme.purple, lineWidth: 1.5))
        .cornerRadius(AppRadius.md)
    }
}

#Preview("PixelTextField") {
    @Previewable @State var empty = ""
    @Previewable @State var filled = "나노"
    @Previewable @State var search = "하늘"
    return ZStack {
        DTheme.bgDeep.ignoresSafeArea()
        VStack(spacing: AppSpacing.lg) {
            PixelTextField(placeholder: "닉네임을 입력해주세요", text: $empty)
            PixelTextField(placeholder: "닉네임을 입력해주세요", text: $filled, isFocused: true)
            PixelTextField(placeholder: "닉네임을 입력해주세요", text: $filled, alignment: .center)
            PixelTextField(placeholder: "작품 검색...", text: $search,
                           size: .compact, icon: "magnifyingglass", showsClearButton: true)
        }
        .padding(AppSpacing.xxxl)
    }
}
