# DioHub for Github

## Summary

DioHub is an open-source unofficial GitHub mobile client, that aims to deliver the ultimate GitHub experience on mobile devices.

### Is the project dead?

No, there is a big update that has been in works for a while now, progress has just been slow because, well, I work on this in my free time. However, I expect to put out a few dev releases in the coming months, and hopefully, a full play store & app store release soon, once everything is ready. Keep an eye on [the releases section](https://github.com/NamanShergill/diohub/releases) if you would like to keep up with the dev builds. There is also a [Telegram group](https://t.me/DiohubApp) for any discussion on the project.

<a href="https://play.google.com/store/apps/details?id=com.felix.diohub"><img src="https://user-images.githubusercontent.com/33877135/129138668-8d48aaf5-c844-4e38-bb9b-78df12af8ea9.png" width="300"></a>

[Alternatively, download the latest apk from releases](https://github.com/NamanShergill/diohub/releases)

---

## Features

- Comprehensive Issues/Pulls timelines and discussion, with ability to view and reply to review comments

- Access to all information from a repository, including pinned issues and issue templates

- Advanced Search with context based filter suggestions and query helpers

- Complete support for GitHub deeplinks

- Completely customizable color palette and fonts, with ability to share them

- Code browsing with support for specific commit browsing, viewing commit history of a specific directory and with syntax highlighting

- User/Home Activity Timeline

- Organization profiles with member lists, repository filters and pinned repositories

- Commits and patch viewer

- GitHub Flavored Markdown Support

- Caching for partial offline support

---

## Roadmap
- [Features Roadmap here](https://github.com/NamanShergill/diohub/issues/41)
- Readme that delves deeper into the application and its features.

## Support

[Like this project? Click here if you would like to support its development!](https://www.buymeacoffee.com/byefelixia)

## Screenshots
![Screenshot_20210806-230536408](https://user-images.githubusercontent.com/33877135/129139265-79be2054-e146-4198-b548-3a42f7e07967.jpg)
![Screenshot_20210806-230547276](https://user-images.githubusercontent.com/33877135/129139267-8473fda5-a780-47a2-b875-99426f429829.jpg)
![Screenshot_20210806-230607898](https://user-images.githubusercontent.com/33877135/129139268-5498be91-d845-4ad7-b5ba-e97fb976e5c6.jpg)
![Screenshot_20210806-230622659](https://user-images.githubusercontent.com/33877135/129139269-2e658867-549d-4bd2-8b12-ffbeeda6d680.jpg)
![Screenshot_20210806-231053046](https://user-images.githubusercontent.com/33877135/129139271-6505e352-ad9d-49be-aeaf-c168f9b4f435.jpg)

## Build Instructions

- [Install Flutter on your system.](https://flutter.dev/docs/get-started/install)
- [Create a GitHub OAuth application.](https://docs.github.com/en/developers/apps/building-oauth-apps/creating-an-oauth-app)
  - Set the `Authorization callback URL` to `auth.felix.diohub://login-callback`.
  - Grant organization access on the authorization screen for any organizations whose repositories you want to browse. Organization owners approve OAuth apps separately; existing grants can be managed from the app's **Settings → GitHub Connection** card or at `https://github.com/settings/connections/applications/<client-id>`.
- Run `git submodule update --init` in the project directory. 
- Create a file under `lib/app` named `keys.dart` with the following content:
    ```dart
  class PrivateKeys {
  static const clientID = '<ClientID of the app from the previous step>';
  static const clientSecret = '<ClientSecret of the app from the previous step>';
  }
  ```
- Run `flutter pub get` and [build](https://docs.flutter.dev/get-started/test-drive) the project.

This readme is just an initial draft so apologies for it not being as comprehensive.
