From: Esteban Urrutia <esteuwu@proton.me>
Subject: [PATCH v2 0/3] SM8450 QoL changes (dispcc)
Date: Sat, 11 Jul 2026 23:10:34 -0400
Message-Id: <20260711-sm8450-qol-dispcc-v2-0-fc1a07ac5601@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/02Nyw6CMBBFf4V07Zh2lJcr/8OwgHaQMUKxg0RD+
 Hd5bFye5NxzJyUUmERdokkFGlnYdwvgIVK2Kbs7AbuFFWpMdGoMSJudYw0v/wTH0lsLOq8wj43
 DuNJq2fWBav5szVuxs7yrB9lhDa1GwzL48N1OR7N6ez9B/O+PBjScUkKizNW5K6998IPvji2pY
 p7nH87iVXK9AAAA
X-Change-ID: 20260711-sm8450-qol-dispcc-09b2951d25b0
To: Bjorn Andersson <andersson@kernel.org>, 
 Michael Turquette <mturquette@baylibre.com>, 
 Stephen Boyd <sboyd@kernel.org>, Brian Masney <bmasney@redhat.com>, 
 Dmitry Baryshkov <lumag@kernel.org>, Danila Tikhonov <danila@jiaxyga.com>
Cc: linux-arm-msm@vger.kernel.org, linux-clk@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 Esteban Urrutia <esteuwu@proton.me>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783825891; l=962;
 i=esteuwu@proton.me; s=20260622; h=from:subject:message-id;
 bh=B6McnTUfRV8hsWOIMcBrUnK11VgMMgYLcjKB6pn/gVM=;
 b=mDyWgsrxFJ2IVs5jLDFOaznan9Cc4Opdlt4irS6y6ULgoIlnlb/9h3nMD/U1E3GTo9rmWh2It
 mpJ/uhHii6ZA6IFHOxX+ymr43JM1ACSigm8v9NJ/DFX9xcHfb8z8+U8
X-Developer-Key: i=esteuwu@proton.me; a=ed25519;
 pk=wToFt4mOAWkzbqb15Ye1hrhevI13vK9BcMUFiQ/me1M=
X-Endpoint-Received: by B4 Relay for esteuwu@proton.me/20260622 with auth_id=835
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

These patches are mainly focused on getting a flickerless boot process
on SM8475 based devices.

Signed-off-by: Esteban Urrutia <esteuwu@proton.me>
---
Changes in v2:
- Split series in subseries (dispcc, dts, qmp, smmu)
- Migrate to qcom_cc_driver_data (Konrad)
- Split mdss patch into 3 patches
- Use Fixes tag where applicable (Krzysztof)
- Link to v1: https://patch.msgid.link/20260622-sm8450-qol-v1-0-37e2ee8df9da@proton.me

---
Esteban Urrutia (3):
      clk: qcom: dispcc-sm8450: Fix disp_cc_mdss_mdp_clk_src ops
      clk: qcom: dispcc-sm8450: Migrate to qcom_cc_driver_data
      clk: qcom: dispcc-sm8450: Keep pll types as is for SM8475

 drivers/clk/qcom/dispcc-sm8450.c | 32 ++++++++++++++++++++++----------
 1 file changed, 22 insertions(+), 10 deletions(-)
---
base-commit: bee763d5f341b99cf472afeb508d4988f62a6ca1
change-id: 20260711-sm8450-qol-dispcc-09b2951d25b0

Best regards,
--  
Esteban Urrutia <esteuwu@proton.me>

