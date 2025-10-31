From: Chuan Liu <chuan.liu@amlogic.com>
Subject: [PATCH v3 0/4] clk: amlogic: optimize the PLL driver
Date: Fri, 31 Oct 2025 16:10:07 +0800
Message-Id: <20251031-optimize_pll_driver-v3-0-92f3b2f36a83@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN9uBGkC/23O2wqDMAyA4VeRXq/DxkO3Xe09xpC2phpQK1XKN
 vHdV4XBBrv8A/mShU3oCSd2SRbmMdBEboiRHRJmWjU0yKmOzSCFQqSQcjfO1NMLq7HrqtpTQM+
 lRnsWJ1maXLC4OXq09NjV2z12S9Ps/HM/EsQ2/Xjw1wuCp1yBLCSA1aXNr6rvXEPmaFzPNjHAl
 5L9/ypAVDIJMrOFhkLpX2Vd1zf3oyAs/gAAAA==
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jerome Brunet <jbrunet@baylibre.com>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Kevin Hilman <khilman@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: linux-amlogic@lists.infradead.org, linux-clk@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuan Liu <chuan.liu@amlogic.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761898227; l=3924;
 i=chuan.liu@amlogic.com; s=20240902; h=from:subject:message-id;
 bh=EIXHJpDNgd4/dzJhbSBB4YpUTUTgFGHOzNPZSvMfSdo=;
 b=E2xrDs0kzXWia5FQI+8iHPTNFBraPMo5rij9PqIA1dpWE4C4gew9KKfjOfDZ6+XiSjBgfC21D
 mHNmULzDasbDVbyPXl/SLksCIf31EvxUgsOkalRBhrslYxPNjPNqJHj
X-Developer-Key: i=chuan.liu@amlogic.com; a=ed25519;
 pk=fnKDB+81SoWGKW2GJNFkKy/ULvsDmJZRGBE7pR5Xcpo=
X-Endpoint-Received: by B4 Relay for chuan.liu@amlogic.com/20240902 with auth_id=203
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series consists of four topics involving the amlogic PLL
driver:
- Fix out-of-range PLL frequency setting.
- Improve the issue of PLL lock failures.
- Add handling for PLL lock failure.
- Optimize PLL enable timing.

For easier review and management, these are submitted as a single
patch series.

The PLL timing optimization changes were merged into our internal
repository quite some time ago and have been verified on a large
number of SoCs:
- Already supported upstream: G12A, G12B, SM1, S4, A1, C3.
- Planned for upstream support: T7, A5, A4, S7, S7D, S6, etc.

Based on the upstream code base, I have performed functional testing
on G12A, A1, A5, A4, T7, S7, S7D, and S6, all of which passed.

Additionally, stress testing using scripts was conducted on A5 and
A1, with over 40,000 and 50,000 iterations respectively, and no
abnormalities were observed. Below is a portion of the stress test
log (CLOCK_ALLOW_WRITE_DEBUGFS has been manually enabled):

- For A5:
  # echo 491520000 > /sys/kernel/debug/clk/hifi_pll/clk_rate
  # cnt=0
  # while true; do
  >     echo "------------ cnt=$cnt -----------"
  >     echo 1 > /sys/kernel/debug/clk/hifi_pll/clk_prepare_enable
  >     en=$(cat /sys/kernel/debug/clk/hifi_pll/clk_prepare_enable 2>/dev/null)
  >     if [ "$en" != "1" ]; then
  >         echo "[ERROR] PLL enable test failed! (clk_prepare_enable=$en)"
  >         break
  >     fi
  > 
  >     echo 0 > /sys/kernel/debug/clk/hifi_pll/clk_prepare_enable
  >     cnt=$((cnt + 1))
  >     echo -e "sleep time: 1 s."
  >     sleep 1
  > done &
  # ------------ cnt=0 -----------
  sleep time: 1 s.
  ------------ cnt=1 -----------
  sleep time: 1 s.
  ------------ cnt=2 -----------
  sleep time: 1 s.
  ...
  ------------ cnt=42076 -----------
  sleep time: 1 s.

- For A1:
  # echo 983040000 > /sys/kernel/debug/clk/hifi_pll/clk_rate
  # cnt=0
  # while true; do
  >     echo "------------ cnt=$cnt -----------"
  >     echo 1 > /sys/kernel/debug/clk/hifi_pll/clk_prepare_enable
  >     en=$(cat /sys/kernel/debug/clk/hifi_pll/clk_prepare_enable 2>/dev/null)
  >     if [ "$en" != "1" ]; then
  >         echo "[ERROR] PLL enable test failed! (clk_prepare_enable=$en)"
  >         break
  >     fi
  > 
  >     echo 0 > /sys/kernel/debug/clk/hifi_pll/clk_prepare_enable
  >     cnt=$((cnt + 1))
  >     echo -e "sleep time: 1 s."
  >     sleep 1
  > done &
  # ------------ cnt=0 -----------
  sleep time: 1 s.
  ------------ cnt=1 -----------
  sleep time: 1 s.
  ------------ cnt=2 -----------
  sleep time: 1 s.
  ...
  ------------ cnt=55051 -----------
  sleep time: 1 s.

Signed-off-by: Chuan Liu <chuan.liu@amlogic.com>
---
Changes in v3:
- Fix some formatting issues.
- Move the 20 us delay after reset into the corresponding if
condition (no delay is needed if there is no reset).
- Move the code that releases rst back to execute before current_en.
- Remove the patch that changes the active level of l_detect.
- Link to v2: https://lore.kernel.org/r/20251030-optimize_pll_driver-v2-0-37273f5b25ab@amlogic.com

Changes in v2:
- Modify the judgment condition of 'm' out of range.
- Split the PLL timing optimization patch to make it easier to review.
- Link to v1: https://lore.kernel.org/r/20251022-optimize_pll_driver-v1-0-a275722fb6f4@amlogic.com

---
Chuan Liu (4):
      clk: amlogic: Fix out-of-range PLL frequency setting
      clk: amlogic: Improve the issue of PLL lock failures
      clk: amlogic: Add handling for PLL lock failure
      clk: amlogic: Optimize PLL enable timing

 drivers/clk/meson/clk-pll.c | 64 +++++++++++++++++++++++++++------------------
 1 file changed, 39 insertions(+), 25 deletions(-)
---
base-commit: 01f3a6d1d59b8e25a6de243b0d73075cf0415eaf
change-id: 20251020-optimize_pll_driver-7bef91876c41

Best regards,
-- 
Chuan Liu <chuan.liu@amlogic.com>

