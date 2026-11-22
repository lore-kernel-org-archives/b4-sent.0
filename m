From: Michael Reeves <michael.reeves077@gmail.com>
Subject: [PATCH v2 0/5] arm64: dts: apple: Add CPU frequency scaling and
 OPPs for M3 family
Date: Sun, 22 Nov 2026 00:18:21 +0000
Message-Id: <20261122-m3-cpufreq-opp-v2-0-3c19963f55ee@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3WNQQ6CMBBFr0K6dkxbCKAr72FYlGGAMUJrC0RDu
 LsF1y5f8v77qwjkmYK4JqvwtHBgO0bQp0Rgb8aOgJvIQkudK6UVDCmgm1tPL7DOAeXNJTVloVD
 XIo6cp5bfR/Be/TjM9YNw2iu70XOYrP8cj4vavb/xRYGETBuJssCsNNmtGww/z2gHUW3b9gWBL
 TiEvgAAAA==
X-Change-ID: 20261121-m3-cpufreq-opp-e6d93a871c2b
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, "Rafael J. Wysocki" <rafael@kernel.org>, 
 Viresh Kumar <viresh.kumar@linaro.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-pm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Michael Reeves <michael.reeves077@gmail.com>, 
 Yureka Lilian <yureka@cyberchaos.dev>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795306712; l=2275;
 i=michael.reeves077@gmail.com; s=20261107; h=from:subject:message-id;
 bh=/koNC4s8lnU15asJdPfp4bY2LX+NiaD8WCHNpdk0oLo=;
 b=UEnk8AVwn5vvlcuSPASfS/pke7z4HaDTII73tGzgzX5eTJJKZNB+y8C9HwwmCOZ7NPPOhuGMC
 6lwI92uHbP8AIs603GOrnWVT52HxEW93eyRBHfsknPFs6lrPCtQrRgN
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=ykwkLcuByJYb/cdLc2UuoYP03pIzwrscEZg30+4tJL8=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20261107 with auth_id=1442
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi folks,

This series adds CPU frequency scaling support, operating performance
point tables, and asymmetric CPU capacity values for the following 
Apple M3 family SoCs:

- T8122 (M3)
- T6030 (M3 Pro)
- T6031 / T6034 (M3 Max)
- T6032 (M3 Ultra)

This series is based on apple-soc/dt-7.5.

Thanks,
Michael

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
Changes in v2:
- T6031: Add missing capacity-dmips-mhz property to cpu_p14 and cpu_p15.
- T6032: Add new patch duplicating die0 CPU capacity, OPP, and
  performance-domain properties onto die1.
- Link to v1: https://patch.msgid.link/20261121-m3-cpufreq-opp-v1-0-42a0c07c48a4@gmail.com

To: Sven Peter <sven@kernel.org>
To: Janne Grunau <j@jannau.net>
To: Neal Gompa <neal@gompa.dev>
To: "Rafael J. Wysocki" <rafael@kernel.org>
To: Viresh Kumar <viresh.kumar@linaro.org>
To: Rob Herring <robh@kernel.org>
To: Krzysztof Kozlowski <krzk+dt@kernel.org>
To: Conor Dooley <conor+dt@kernel.org>
To: Hector Martin <marcan@marcan.st>
Cc: asahi@lists.linux.dev
Cc: linux-arm-kernel@lists.infradead.org
Cc: linux-pm@vger.kernel.org
Cc: devicetree@vger.kernel.org
Cc: linux-kernel@vger.kernel.org

---
Janne Grunau (2):
      arm64: dts: apple: t8122: Add CPU frequency scaling and OPPs
      arm64: dts: apple: t6030: Add CPU frequency scaling and OPPs

Michael Reeves (2):
      dt-bindings: cpufreq: apple,cluster-cpufreq: Add M3 family compatibles
      arm64: dts: apple: t6032: Add CPU frequency scaling and OPPs

Yureka Lilian (1):
      arm64: dts: apple: t6031: Add CPU frequency scaling and OPPs

 .../bindings/cpufreq/apple,cluster-cpufreq.yaml    |   6 +-
 arch/arm64/boot/dts/apple/t6030.dtsi               | 228 +++++++++++++++++++++
 arch/arm64/boot/dts/apple/t6031-base.dtsi          | 215 +++++++++++++++++++
 arch/arm64/boot/dts/apple/t6031-dieX.dtsi          |  21 ++
 arch/arm64/boot/dts/apple/t6032.dtsi               |  48 +++++
 arch/arm64/boot/dts/apple/t8122.dtsi               | 210 +++++++++++++++++++
 6 files changed, 727 insertions(+), 1 deletion(-)
---
base-commit: 477f3d0f46b0d885f162a64d13ca51e2f7afa542
change-id: 20261121-m3-cpufreq-opp-e6d93a871c2b

Best regards,
--  
Michael Reeves <michael.reeves077@gmail.com>

