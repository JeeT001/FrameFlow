//
//  SupabaseClient.swift
//  FrameFlow
//

import Foundation
import Supabase

enum SupabaseClientProvider {
    static let shared: SupabaseClient = makeClient()

    static var isConfigured: Bool {
        !Config.supabaseURL.isEmpty && !Config.supabaseAnonKey.isEmpty
    }

    private static func makeClient() -> SupabaseClient {
        guard
            isConfigured,
            let url = URL(string: Config.supabaseURL)
        else {
            #if DEBUG
            print(
                "[FrameFlow] Supabase credentials missing or invalid. " +
                "Copy Config.example.swift to Config.swift and add your project URL and anon key."
            )
            #endif

            return SupabaseClient(
                supabaseURL: URL(string: "https://placeholder.supabase.co")!,
                supabaseKey: "placeholder-anon-key"
            )
        }

        return SupabaseClient(
            supabaseURL: url,
            supabaseKey: Config.supabaseAnonKey
        )
    }
}
