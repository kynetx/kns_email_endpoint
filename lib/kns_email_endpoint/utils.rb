module KNSEmailEndpoint

  module Utils
    def addrextract(address)
      #grab label
      beforeat = address.split("@", 2)[0]
      s = beforeat.split("+")
      appidversion = s[0]
      label = s[1] || ""
      a = appidversion.split(".")
      appid = a[0]
      version = a[1] || "production"
      return appid, version, label
    end
  end

end
