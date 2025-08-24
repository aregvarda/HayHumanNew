//
//  ChurchFilters.swift
//  HayHuman
//
//  Created by Арег Варданян on 23.08.2025.
//



import SwiftUI

struct ChurchFiltersRow: View {
    @Binding var filter: ChurchFilter
    @Binding var selectedCountry: String?
    let topCountries: [String]
    let onMoreCountries: () -> Void
    let onOpenFilters: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("", selection: $filter) {
                Text("filter_all").lineLimit(1).tag(ChurchFilter.all)
                Text("filter_active").lineLimit(1).tag(ChurchFilter.active)
                Text("filter_inactive").lineLimit(1).tag(ChurchFilter.inactive)
            }
            .pickerStyle(.segmented)
            .padding(6)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black.opacity(0.06), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
            .padding(.horizontal, 16)

            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button { selectedCountry = nil } label: {
                            Text("all_countries")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(selectedCountry == nil ? Color.purple.opacity(0.15) : Color(.systemGray6))
                                .clipShape(Capsule())
                                .contentShape(Capsule())
                                .lineLimit(1)
                                .overlay(
                                    Capsule().stroke(Color.black.opacity(0.06), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)

                        ForEach(topCountries, id: \.self) { c in
                            Button { selectedCountry = c } label: {
                                Text(c)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(selectedCountry == c ? Color.purple.opacity(0.15) : Color(.systemGray6))
                                    .clipShape(Capsule())
                                    .contentShape(Capsule())
                                    .lineLimit(1)
                                    .overlay(
                                        Capsule().stroke(Color.black.opacity(0.06), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: onMoreCountries) {
                            HStack(spacing: 6) { Image(systemName: "ellipsis"); Text("more") }
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                                .contentShape(Capsule())
                                .lineLimit(1)
                                .overlay(
                                    Capsule().stroke(Color.black.opacity(0.06), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 0)

                Button(action: onOpenFilters) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.secondary)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color(.systemGray5)))
                        .overlay(
                            Circle().stroke(Color.black.opacity(0.06), lineWidth: 1)
                        )
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }
        }
        .padding(.bottom, 6)
    }
}
