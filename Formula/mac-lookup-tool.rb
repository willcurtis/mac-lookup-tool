class MacLookupTool < Formula
  desc "CLI tool to look up MAC address vendors"
  homepage "https://github.com/willcurtis/mac-lookup-tool"
  url "https://github.com/willcurtis/mac-lookup-tool/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "4e47d47d5fb178c49b67993a570891fa2e23736563079c6d1f86bf2bcc40469c"
  license "MIT"

  def install
    bin.install "mac_lookup.sh" => "mac-lookup"
  end

  test do
    system "#{bin}/mac-lookup", "00:11:22:33:44:55"
  end
end
