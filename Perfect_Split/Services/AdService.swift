import Foundation
import UIKit
import AppTrackingTransparency

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

@MainActor
final class AdService: NSObject {
    static let shared = AdService()

    private let interstitialFrequency = 4
    private var naturalBreakCount = 0
    private var hasStarted = false

    #if canImport(GoogleMobileAds)
    private var interstitial: InterstitialAd?
    private var rewardedAd: RewardedAd?
    #if DEBUG
    // Google 공개 테스트 Unit ID — 개발용. AdMob 계정에 영향 없음.
    private let interstitialUnitID = "ca-app-pub-3940256099942544/4411468910"
    private let rewardedUnitID = "ca-app-pub-3940256099942544/1712485313"
    #else
    // 실제 프로덕션 Unit ID — App Store 빌드에서만 사용
    private let interstitialUnitID = "ca-app-pub-3398247421662455/4611177935"
    private let rewardedUnitID = "ca-app-pub-3398247421662455/7133399498"
    #endif
    #endif

    private override init() {
        super.init()
    }

    func startAfterLaunch() {
        guard !hasStarted else { return }
        hasStarted = true

        #if canImport(GoogleMobileAds)
        Task {
            try? await Task.sleep(for: .milliseconds(350))
            _ = await ATTrackingManager.requestTrackingAuthorization()
            await MobileAds.shared.start()
            loadInterstitial()
            loadRewardedAd()
        }
        #endif
    }

    func showInterstitialAtNaturalBreak() {
        naturalBreakCount += 1
        guard naturalBreakCount % interstitialFrequency == 0 else { return }

        #if canImport(GoogleMobileAds)
        guard let interstitial,
              let presenter = UIApplication.shared.topMostViewController else {
            loadInterstitial()
            return
        }
        interstitial.present(from: presenter)
        self.interstitial = nil
        loadInterstitial()
        #endif
    }

    func showRewardedExtraLife(onReward: @escaping () -> Void) {
        showRewardedAd(onReward: onReward)
    }

    func showRewardedDivisionShard(
        onReward: @escaping () -> Void,
        onUnavailable: (() -> Void)? = nil
    ) {
        showRewardedAd(onReward: onReward, onUnavailable: onUnavailable)
    }

    private func showRewardedAd(
        onReward: @escaping () -> Void,
        onUnavailable: (() -> Void)? = nil
    ) {
        #if canImport(GoogleMobileAds)
        guard let rewardedAd,
              let presenter = UIApplication.shared.topMostViewController else {
            loadRewardedAd()
            onUnavailable?()
            return
        }
        rewardedAd.present(from: presenter) {
            onReward()
        }
        self.rewardedAd = nil
        loadRewardedAd()
        #else
        onReward()
        #endif
    }

    #if canImport(GoogleMobileAds)
    private func loadInterstitial() {
        Task {
            do {
                let ad = try await InterstitialAd.load(
                    with: interstitialUnitID,
                    request: Request()
                )
                ad.fullScreenContentDelegate = self
                interstitial = ad
            } catch {
                interstitial = nil
            }
        }
    }

    private func loadRewardedAd() {
        Task {
            do {
                let ad = try await RewardedAd.load(
                    with: rewardedUnitID,
                    request: Request()
                )
                ad.fullScreenContentDelegate = self
                rewardedAd = ad
            } catch {
                rewardedAd = nil
            }
        }
    }
    #endif
}

#if canImport(GoogleMobileAds)
extension AdService: FullScreenContentDelegate {
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        loadInterstitial()
    }

    func ad(
        _ ad: FullScreenPresentingAd,
        didFailToPresentFullScreenContentWithError error: Error
    ) {
        loadInterstitial()
    }
}
#endif

private extension UIApplication {
    var topMostViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .topMostPresentedViewController
    }
}

private extension UIViewController {
    var topMostPresentedViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.topMostPresentedViewController
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostPresentedViewController ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostPresentedViewController ?? tabBarController
        }
        return self
    }
}
