import SwiftUI

class ProfileViewModel: ObservableObject {
    @Published var userStats: UserStatsDTO?
    @Published var userInterests: [String] = []
    @Published var userSocialMedia: UserSocialMediaDTO?
    @Published var isLoadingStats: Bool = false
    @Published var isLoadingInterests: Bool = false
    @Published var isLoadingSocialMedia: Bool = false
    @Published var showDrawer: Bool = false
    @Published var errorMessage: String?
    
    private let apiService: IAPIService
    
    init(apiService: IAPIService = MockAPIService.isMocking ? MockAPIService() : APIService()) {
        self.apiService = apiService
    }
    
    func fetchUserStats(userId: UUID) async {
        await MainActor.run {
            self.isLoadingStats = true
        }
        
        if let url = URL(string: APIService.baseURL + "users/\(userId)/stats") {
            do {
                let stats: UserStatsDTO = try await self.apiService.fetchData(from: url, parameters: nil)
                await MainActor.run {
                    self.userStats = stats
                    self.isLoadingStats = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load user stats: \(error.localizedDescription)"
                    self.isLoadingStats = false
                }
            }
        }
    }
    
    func fetchUserInterests(userId: UUID) async {
        await MainActor.run {
            self.isLoadingInterests = true
        }
        
        if let url = URL(string: APIService.baseURL + "users/\(userId)/interests") {
            do {
                let interests: [String] = try await self.apiService.fetchData(from: url, parameters: nil)
                await MainActor.run {
                    self.userInterests = interests
                    self.isLoadingInterests = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load user interests: \(error.localizedDescription)"
                    self.isLoadingInterests = false
                }
            }
        }
    }
    
    func addUserInterest(userId: UUID, interest: String) async {
        if let url = URL(string: APIService.baseURL + "users/\(userId)/interests") {
            do {
                let _ = try await self.apiService.sendData(
                    interest,
                    to: url,
                    parameters: nil
                )
                // Refresh interests after adding
                await fetchUserInterests(userId: userId)
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to add interest: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func fetchUserSocialMedia(userId: UUID) async {
        await MainActor.run {
            self.isLoadingSocialMedia = true
        }
        
        if let url = URL(string: APIService.baseURL + "users/\(userId)/social-media") {
            do {
                let socialMedia: UserSocialMediaDTO = try await self.apiService.fetchData(from: url, parameters: nil)
                await MainActor.run {
                    self.userSocialMedia = socialMedia
                    self.isLoadingSocialMedia = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to load social media: \(error.localizedDescription)"
                    self.isLoadingSocialMedia = false
                }
            }
        }
    }
    
    func updateSocialMedia(userId: UUID, whatsappLink: String?, instagramLink: String?) async {
        if let url = URL(string: APIService.baseURL + "users/\(userId)/social-media") {
            do {
                let updateDTO = UpdateUserSocialMediaDTO(
                    whatsappLink: whatsappLink,
                    instagramLink: instagramLink
                )
                
                let updatedSocialMedia: UserSocialMediaDTO = try await self.apiService.updateData(
                    updateDTO,
                    to: url,
                    parameters: nil
                )
                
                await MainActor.run {
                    self.userSocialMedia = updatedSocialMedia
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to update social media: \(error.localizedDescription)"
                }
            }
        }
    }
    
    func loadAllProfileData(userId: UUID) async {
        await fetchUserStats(userId: userId)
        await fetchUserInterests(userId: userId)
        await fetchUserSocialMedia(userId: userId)
    }
} 
