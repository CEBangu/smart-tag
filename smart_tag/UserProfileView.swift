//
//  UserProfileView.swift
//  smart_tag
//
//  Created by Ciprian Bangu on 2025-04-03.
//

import SwiftUI

struct UserProfileView: View {
    // Username passed from the previous view (the tag name)
    let username: String
    
    var displayName: String {
        if username.starts(with: "@") {
            return String(username.dropFirst())
        } else {
            return username
        }
    }

    // Mock data for the profile
    let profilePicName = "person.crop.circle.fill" // Placeholder system image
    let postCount = Int.random(in: 10...200) // Random placeholder
    let followerCount = Int.random(in: 200...1000)
    let followingCount = Int.random(in: 100...800)
    let fullName = "Friendo McFriend"
    let bio = "Computer Vision is cool!"
    let link = "https://github.com/CEBangu/smart-tag"

    // State for the selected content tab
    @State private var selectedTab: ProfileTab = .grid

    // Define the grid layout
    let columns: [GridItem] = Array(repeating: .init(.flexible(), spacing: 1), count: 3)

    // Environment for dismissing (if needed, e.g., custom back button)
    @Environment(\.dismiss) var dismiss

    enum ProfileTab {
        case grid, reels, tagged
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // --- Profile Header ---
                ProfileHeaderView(
                    profilePicName: profilePicName,
                    postCount: postCount,
                    followerCount: followerCount,
                    followingCount: followingCount
                )
                .padding(.horizontal)
                .padding(.top, 5) // Adjust top padding as needed

                // --- Name, Bio, Link ---
                ProfileInfoView(
                    fullName: fullName,
                    bio: bio,
                    link: link,
                    username: username // Pass username for Threads badge simulation
                )
                .padding(.horizontal)
                .padding(.top, 10)

                // --- Action Buttons ---
                ProfileActionButtonsView()
                    .padding(.horizontal)
                    .padding(.vertical, 15)

                // --- Content Tabs ---
                ProfileTabsView(selectedTab: $selectedTab)
                    // Make tabs sticky using LazyVStack if desired, but simple HStack is fine for layout

                // --- Content Grid/View ---
                // Switch content based on selected tab
                // For now, just showing the grid regardless of tab
                PhotoGridView(columns: columns)
                    .padding(.top, 1) // Small gap between tabs and grid

            } // End main VStack
        } // End ScrollView
        // --- Navigation Bar ---
        .navigationTitle(displayName) // Display username in the title
        .navigationBarTitleDisplayMode(.inline) // Use inline style like Instagram
        .toolbar {
            // Right-side buttons
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    print("Add content tapped")
                } label: {
                    Image(systemName: "plus.app") // Or "plus.square"
                        .foregroundColor(.primary) // Use primary for auto light/dark mode
                }

                Button {
                    print("Menu tapped")
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .foregroundColor(.primary)
                }
            }
        }
        // Optional: Change background color if needed
        // .background(Color(.systemBackground)) // Use system background
    }
}

// MARK: - Subviews for UserProfileView

struct ProfileHeaderView: View {
    let profilePicName: String
    let postCount: Int
    let followerCount: Int
    let followingCount: Int

    var body: some View {
        HStack(spacing: 20) {
            // Profile Picture
            Image(systemName: profilePicName) // Use system name or load image asset
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .foregroundColor(.gray) // Color for placeholder

            Spacer() // Push stats to the right

            // Stats
            HStack(spacing: 25) {
                StatItemView(count: postCount, label: "posts")
                StatItemView(count: followerCount, label: "followers")
                StatItemView(count: followingCount, label: "following")
            }
        }
    }
}

struct StatItemView: View {
    let count: Int
    let label: String

    var body: some View {
        VStack {
            Text("\(count)")
                .font(.system(size: 16, weight: .semibold))
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(.primary) // Adjust color if needed
        }
    }
}

struct ProfileInfoView: View {
    let fullName: String
    let bio: String
    let link: String
    let username: String // Needed for Threads badge simulation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(fullName)
                .font(.system(size: 14, weight: .semibold))

            Text(bio)
                .font(.system(size: 14))
                 // Allows multiple lines if bio contains \n

            // Link simulation
            if !link.isEmpty {
                Text(link)
                    .font(.system(size: 14))
                    .foregroundColor(.blue) // Standard link color
            }

            // Threads badge simulation (if needed)
            // Text("@\(username)")
            //     .font(.system(size: 13))
            //     .padding(.horizontal, 8)
            //     .padding(.vertical, 3)
            //     .background(Color.gray.opacity(0.2))
            //     .clipShape(Capsule())
            //     .padding(.top, 5)

        }
        .frame(maxWidth: .infinity, alignment: .leading) // Ensure VStack takes full width
    }
}

struct ProfileActionButtonsView: View {
    var body: some View {
        HStack(spacing: 8) {
            ActionButton(title: "Edit profile")
            ActionButton(title: "Share profile")
            // Add Friend button simulation
            Button { } label: {
                Image(systemName: "person.badge.plus")
                    .padding(8)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .foregroundColor(.primary)
            }
        }
    }
}

struct ActionButton: View {
    let title: String
    var body: some View {
        Button { } label: {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundColor(.primary) // Use primary for text color adapting to light/dark
        }
    }
}

struct ProfileTabsView: View {
    @Binding var selectedTab: UserProfileView.ProfileTab

    var body: some View {
        HStack {
            TabButton(icon: "squareshape.split.2x2", tab: .grid, selectedTab: $selectedTab)
            TabButton(icon: "play.rectangle", tab: .reels, selectedTab: $selectedTab)
            TabButton(icon: "person.crop.rectangle.stack", tab: .tagged, selectedTab: $selectedTab)
        }
        .frame(height: 44) // Standard tab bar height
        .overlay(alignment: .bottom) {
             // Simple indicator line
             Rectangle()
                 .frame(height: 1)
                 .foregroundColor(.gray.opacity(0.3))
                 .padding(.top, -1) // Position it just below the icons
        }
    }
}

struct TabButton: View {
    let icon: String
    let tab: UserProfileView.ProfileTab
    @Binding var selectedTab: UserProfileView.ProfileTab

    var body: some View {
        Button {
            selectedTab = tab
        } label: {
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == tab ? .primary : .gray)

                Spacer() // Pushes indicator down

                // Indicator for selected tab
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(selectedTab == tab ? .primary : .clear)
            }
        }
    }
}

struct PhotoGridView: View {
    let columns: [GridItem]

    var body: some View {
        // LazyVGrid automatically handles arranging items in columns
        LazyVGrid(columns: columns, spacing: 1) {
            // Create placeholder content
            ForEach(0..<15) { _ in // Display 15 placeholder items
                Rectangle()
                    .fill(Color.gray.opacity(0.3)) // Placeholder color
                    .aspectRatio(1, contentMode: .fill) // Make them square
            }
        }
    }
}
