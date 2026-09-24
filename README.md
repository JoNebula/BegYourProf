# BegYourProf ✦

지도교수님께 후광을 씌우는 작은 macOS 메뉴 막대 앱입니다. 기본으로 들어 있는 **합성 아바타**로 바로 실행할 수 있고, 원하는 사진을 직접 골라 바꿀 수 있습니다. 후광을 화면 위에서 끌어 이동하거나 테두리를 끌어 크기를 조절하세요. `경배하기`를 누르면 횟수가 올라갑니다.

## 설치

macOS 13 이상에서 [Releases](https://github.com/JoNebula/BegYourProf/releases)의 ZIP을 풀고 `BegYourProf.app`을 응용 프로그램 폴더에 옮깁니다. 이 앱은 개발자 인증 및 공증을 거치지 않은 개인 프로젝트입니다. 처음 실행할 때 macOS가 차단하면 Finder에서 앱을 Control-클릭하고 **열기**를 선택하세요.

## 사용법

- 사진을 누르거나 메뉴 막대의 **✦ BegYourProf → 사진 넣기 / 바꾸기…**에서 사진을 고릅니다.
- **기본 아바타로 돌아가기**를 누르면 합성 아바타가 다시 나타납니다.
- 카드의 빈 곳을 끌면 이동하고, 테두리를 끌면 크기가 바뀝니다.
- `×`는 후광을 숨깁니다. 메뉴 막대에서 다시 켜거나 완전히 종료할 수 있습니다.
- **경배하기**를 누르면 카운트가 저장됩니다.

선택한 사진은 앱 내부나 이 저장소로 복사되지 않습니다. **이 Mac의** `~/Library/Application Support/BegYourProf/portrait`에만 저장되며, 기본 아바타로 돌아가면 해당 파일이 삭제됩니다. 배포 ZIP에는 합성 아바타만 포함됩니다.

## 소스에서 빌드

Xcode Command Line Tools가 필요합니다.

```bash
./scripts/check-public-assets.sh
./scripts/build.sh
./scripts/package.sh
```

`dist/BegYourProf.app`과 배포 ZIP이 생성됩니다. 빌드는 Apple Silicon과 Intel을 모두 포함하는 universal 앱을 만들고 로컬 ad hoc 서명을 적용합니다. 코드를 수정해 배포할 때는 직접 서명과 공증을 진행할 수 있습니다.

## 기본 아바타

`Assets/default-avatar.png`는 특정 실존 인물의 사진이 아닌 합성 이미지입니다. 자신의 사진을 이 파일과 바꿔 공개 저장소에 커밋하지 마세요. 앱 안에서 사진을 선택하면 개인 컴퓨터에만 저장됩니다.

## 라이선스

코드와 기본 합성 아바타는 [MIT License](LICENSE)로 배포합니다.
