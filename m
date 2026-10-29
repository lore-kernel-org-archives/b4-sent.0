From: Muzaffer Kadir <muzafferkadir@mainlining.org>
Subject: [PATCH v7 00/11] Add Initial Support For MSM8952, Add General
 Mobile Shamrock
Date: Fri, 30 Oct 2026 00:02:31 +0300
Message-Id: <20261030-msm8952-initial-support-v7-0-ad748ace375d@mainlining.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/33OTWrDMBAF4KsErasyGus3q96jdGFLY0eQ2EZyT
 Uvw3SuHUgy1s3zDzDfvzjKlSJmdT3eWaI45Dn0J5uXE/KXuO+IxlMwQUIMDx2/5Zp1CHvs4xfr
 K8+c4DmniGmpQziMJRaxcj4na+PWQ3z9KvsQ8Den78WgW6/TXFHhozoIDBzISlbGNQvl2q2N/L
 Wt99zqkjq3wjFtMH2NYMOOsL3sYAoldrNpgKI6xqmCN022oWkJnm11M/mEC4EkzWTDywXtRe43
 gdzG1wcSTZqpgwioDRjqHtI/pDYb2GNNrMzAhBNv4Vv7HlmX5AShATUJEAgAA
X-Change-ID: 20260909-msm8952-initial-support-60a059c2e15e
To: Srinivas Kandagatla <srini@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Joerg Roedel (AMD)" <joro@8bytes.org>, 
 Will Deacon <will@kernel.org>, Robin Murphy <robin.murphy@arm.com>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Rajendra Nayak <quic_rjendra@quicinc.com>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Jassi Brar <jassisinghbrar@gmail.com>, Abel Vesa <abelvesa@kernel.org>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney+clk@redhat.com>, 
 Jerome Brunet <jbrunet+clk@baylibre.com>, 
 Rob Clark <robin.clark@oss.qualcomm.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, 
 Abhinav Kumar <abhinav.kumar@linux.dev>, 
 Jessica Zhang <jesszhan0024@gmail.com>, Sean Paul <sean@poorly.run>, 
 Marijn Suijten <marijn.suijten@somainline.org>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Krishna Manikandan <quic_mkrishn@quicinc.com>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Kees Cook <kees@kernel.org>, 
 Tony Luck <tony.luck@intel.com>, 
 "Guilherme G. Piccoli" <gpiccoli@igalia.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>
Cc: David Heidelberg <david@ixit.cz>, phone-devel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, iommu@lists.linux.dev, 
 linux-watchdog@vger.kernel.org, linux-clk@vger.kernel.org, 
 dri-devel@lists.freedesktop.org, freedreno@lists.freedesktop.org, 
 linux-remoteproc@vger.kernel.org, linux-input@vger.kernel.org, 
 Muzaffer Kadir <muzafferkadir@mainlining.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793307755; l=5600;
 i=muzafferkadir@mainlining.org; s=20260816; h=from:subject:message-id;
 bh=f/710DMBCeH1DaZcIhMQg0VmZNSOMZTfOUmb7qsdEJE=;
 b=MgPS4pbxlSjUhNTk+Az7Fn1LktMh5NrC7Wgi+tYZ9+LQQbW6OH6O0BQHHK6uSn+bFIuW6jzlx
 /RC7jpA4POJCye1AG7tabe/zFHyzPhFH5ghXiOuXXiJraVHh+pFTVPU
X-Developer-Key: i=muzafferkadir@mainlining.org; a=ed25519;
 pk=4zkv4suQ3cYcO4Z7CrV8JSSjEGLBGepUtvQCFjgnYIU=
X-Endpoint-Received: by B4 Relay for muzafferkadir@mainlining.org/20260816 with auth_id=954
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

MSM8952 is a SoC with 8 core cpu and Adreno 405 gpu.

Ported without uart connection. ramoops and usb
mainly used to debug.
USB is not enabled in this series because it
depends on the not yet upstreamed (and not developed by me)
pmi8950_smbcharger.

General Mobile shamrock display panel driver
is generated using MSM8916's mdss dsi panel
driver generator and tested with it. I didn't
include it.

Pinctrl driver was submitted and merged here:
https://lore.kernel.org/all/20260907-msm8952-pinctrl-v5-0-9a2d8d72ffdb@mainlining.org/

Signed-off-by: Muzaffer Kadir <muzafferkadir@mainlining.org>
---
Changes in v7:
- Dropped the tsens sensors which was renamed at v6 and l2 sensor.
- Wired mdss mpm (sashiko).
- Changed size of master_stats addresses that exist on rpm_msg_ram from
  0x14 to 0x50 (sashiko).
- Renamed crypto_dma and usb_dma to cryptobam and usbbam.
- Changed device dts, si-en led label property to color and function
  properties and replaced multi-led function from indicator to status.
- Fixed hexagon_smsm interrupt, also added adsp_smsm.
- Added opp-tables to sdhci_1 and sdhci_2.
- Link to v6: https://patch.msgid.link/20261028-msm8952-initial-support-v6-0-e07ddd8bcf4c@mainlining.org

Changes in v6:
- Use one-per-line in SoC dtsi as Konrad requested.
- Drop unneeded dr_mode in usb as Konrad requested.
- Drop 1651200000 from pll_opp_table_c1 as Konrad requested.
- Added new patches for more msm8952 specific compatibles as Konrad
  requested.
- Renamed 'aoss0', 'modem', 'camera' sensors to generic names as Konrad
  requested.
- Drop clock-frequency from timer as Konrad requested.
- Switched passive and hot of cpu0-3-thermal trip types
- Link to v5: https://patch.msgid.link/20261011-msm8952-initial-support-v5-0-1857074992ec@mainlining.org

Changes in v5:
- Added opp table for spi and uart.
- Wired all i2c and spi power-domains
- Dropped default slope from thermal driver.
- Link to v4: https://patch.msgid.link/20261006-msm8952-initial-support-v4-0-ecdcc1ac620c@mainlining.org

Changes in v4:
- Dropped 1651200000 freq on cluster 1 because it depends on speedbin 3
  and speedbin is not included in this patch series
- Dropped applied patches
- Changed mdss_dsi0 power-domain to MDSS_GDSC
- Reformatted SoC dtsi file
- Added the remaining reserved-memory entries for not added parts
- Rename adsp_mem to adsp_fw_mem
- Drop the "ts-" prefix of touchscreen pinctrl in device dts.
- Link to v3: https://patch.msgid.link/20260921-msm8952-initial-support-v3-0-b96fd3fe298b@mainlining.org

Changes in v3:
- Improved GCC driver, also rewrote resets part
- Rewrote the dt-binding side of gcc
- Reformatted Device tree files with dt-check-style tool
- Added reset to sdhci1 and sdhci2
- Added cx regulator to gcc
- Added gcc commit messages that it is a derived driver
- Dropped adsp_mem, renamed lpass_mem to adsp_mem
- Changed tusb320 interrupt from rising to falling as downstream uses
- Link to v2: https://patch.msgid.link/20260916-msm8952-initial-support-v2-0-798c2602dde1@mainlining.org

Changes in v2:
- Changed device dts file as David's and Konrad's suggestions
- Removed accidental duplicated clock assigments and fixed wrong gcc gp1,gp2
  and gp3 parent_maps
- Updated commit messages to make it wrapped at 72 character.
- Fixed spi1 tlmm node naming
- Added remaining spi and i2c nodes
- Wired up mpm
- Add mmio-sram to rpm_msg_ram
- Reformatted msm8952.dtsi
- Removed rpmcc-msm8952 driver entry and replaced it with rpmcc-msm8976
- Merged sdhci tlmm pins to single nodes, now it is similar to existing SoCs
- Rebased to latest linux-next, now storage works
- Removed polling-delay properties from tsens
- Link to v1: https://lore.kernel.org/r/20260912-msm8952-initial-support-v1-0-0e742578b524@mainlining.org

---
Muzaffer Kadir (11):
      dt-bindings: nvmem: Add compatible for MSM8952
      dt-bindings: iommu: qcom,iommu: Add MSM8952 IOMMU to SMMUv2 compatibles
      dt-bindings: watchdog: qcom-wdt: Document MSM8952 watchdog
      dt-bindings: sram: qcom,imem: Document MSM8952 compatible
      dt-bindings: mailbox: qcom: Add MSM8952 APCS compatible
      dt-bindings: clock: qcom,a53pll: Add MSM8952 compatible
      dt-bindings: display: msm: dsi-controller-main: Add MSM8952 compatible
      dt-bindings: remoteproc: qcom: adsp: Add MSM8952 ADSP compatible
      arm64: dts: qcom: Add initial support for MSM8952
      dt-bindings: input: touchscreen: goodix: Add binding for GT970
      arm64: dts: qcom: generalmobile-shamrock: new device

 .../devicetree/bindings/clock/qcom,a53pll.yaml     |   25 +-
 .../bindings/display/msm/dsi-controller-main.yaml  |    2 +
 .../bindings/input/touchscreen/goodix.yaml         |   35 +-
 .../devicetree/bindings/iommu/qcom,iommu.yaml      |    1 +
 .../bindings/mailbox/qcom,apcs-kpss-global.yaml    |    5 +
 .../devicetree/bindings/nvmem/qcom,qfprom.yaml     |    1 +
 .../devicetree/bindings/remoteproc/qcom,adsp.yaml  |   31 +-
 .../devicetree/bindings/sram/qcom,imem.yaml        |    1 +
 .../devicetree/bindings/watchdog/qcom-wdt.yaml     |    1 +
 arch/arm64/boot/dts/qcom/Makefile                  |    1 +
 .../dts/qcom/msm8952-generalmobile-shamrock.dts    |  442 +++
 arch/arm64/boot/dts/qcom/msm8952.dtsi              | 2909 ++++++++++++++++++++
 12 files changed, 3416 insertions(+), 38 deletions(-)
---
base-commit: 151a134a4e6ec66f69db8750c66006f5207f7a9d
change-id: 20260909-msm8952-initial-support-60a059c2e15e

Best regards,
--  
Muzaffer Kadir <muzafferkadir@mainlining.org>

