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
                Text("filter_all").tag(ChurchFilter.all)
                Text("filter_active").tag(ChurchFilter.active)
                Text("filter_inactive").tag(ChurchFilter.inactive)
            }
            .pickerStyle(.segmented)
            .padding(6)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.horizontal, 16)

            HStack(spacing: 8) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button { selectedCountry = nil } label: {
                            Text("all_countries")
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(selectedCountry == nil ? Color.purple.opacity(0.15)
                                                                  : Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        ForEach(topCountries, id: \.self) { c in
                            Button { selectedCountry = c } label: {
                                Text(c)
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(selectedCountry == c ? Color.purple.opacity(0.15)
                                                                     : Color(.systemGray6))
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }

                        Button(action: onMoreCountries) {
                            HStack(spacing: 6) { Image(systemName: "ellipsis"); Text("more") }
                                .font(.subheadline.weight(.semibold))
                                .padding(.horizontal, 12).padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 16)
                }

                Spacer(minLength: 0)

                Button(action: onOpenFilters) {
                    HStack(spacing: 6) { Image(systemName: "slider.horizontal.3"); Text("filters") }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 12).padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .padding(.trailing, 16)
            }
        }
        .padding(.bottom, 6)
    }
}
