cask "name-tag" do
  version :latest
  sha256 :no_check

  url "https://github.com/greglamb/macos-name-tag-app/releases/latest/download/NameTag.dmg"
  name "Name Tag"
  desc "Menu bar app that displays your hostname or a custom label"
  homepage "https://github.com/greglamb/macos-name-tag-app"

  depends_on macos: ">= :ventura"

  app "Name Tag.app"

  zap trash: [
    "~/Library/Preferences/com.nametag.app.plist",
  ]
end
