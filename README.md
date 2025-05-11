# Codear

**Version:** 1.1.0-alpha.1  
**Status:** Alpha release

---

## ダウンロード

最新の APK は [Releases ページ](https://github.com/ozwshn/codear/releases) からどうぞ。

---

## 機能一覧

- コード再生デモ  
- コード当てクイズ（トライアド・セブンス付き）  
- サウンドフォント切替  
- 難易度 & プリセット管理  
- カスタムプリセットの作成・編集・並び替え・削除  

---

## インストール手順

1. Android 端末で［設定］→［セキュリティ］→「提供元不明のアプリ」を許可  
2. ダウンロードした `app-release.apk` をタップしてインストール  

---

## ビルド手順

```bash
# リポジトリをクローン
git clone https://github.com/あなたのユーザー名/リポジトリ名.git
cd リポジトリ名

# 依存を取得
flutter pub get

# Release APK ビルド
flutter build apk --release
# artifact は build/app/outputs/flutter-apk/app-release.apk に生成されます
