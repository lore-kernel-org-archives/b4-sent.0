From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 00/11] Pixel 3 XL display panel support
Date: Thu, 24 Sep 2026 16:01:28 +0200
Message-Id: <20260924-crosshatch-panel-v2-0-08d5c7bf72fc@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/2WNyw6CMBBFf4XM2pq2iZW68j8Ii9IOdowB0qkEJ
 fy7PJYuT3LuuTMwJkKGWzFDwpGY+m4FfSrAR9c9UFBYGbTURpZSCZ965uiyj2JwHb6ENB5LZ2z
 bXFtYZ0PClqY9WdUH87t5os9bZzMice7TZ/8c1eYdeavlf35UQoqABu1F6eCsudNE+ey/UC/L8
 gOjaRtowAAAAA==
X-Change-ID: 20260801-crosshatch-panel-06ce8a69fb7f
To: Dzmitry Sankouski <dsankouski@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>
Cc: Petr Vorel <petr.vorel@gmail.com>, dri-devel@lists.freedesktop.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1970; i=david@ixit.cz;
 h=from:subject:message-id; bh=6JGHabwRWmpDCBWI59Z99X50itb/iYbgKpJnZE32Ln0=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqtS08Dk8l2uXKE36uyRLVWoZjZkieSzDdrqR9I
 dCdfi2WxOWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCarUtPAAKCRBgAj/E00kg
 cuyAD/9osXGW+rWDY7F1S0MsR2H7g77JFd+exO2DFA+ZAx91qW6Xp2her/gV3xXiSEuPezjMNTv
 H1bLed5aS3whJwxlsKSciLtJmGyplhv+b1Qk2+F7Qsv1Xz5ov06UmUciBgD7jtzn8scUvY0Lh0u
 1Dd2a+/551xTYi5ux16P5ib9GjgZnUn7IXMtH/05Y0ENdoQXwdSb7Bi4Dfbdz8k1YHKc8HOuYUg
 IbPoyCCQfP8XSP3OCKff4p8//ym3pufbmuKHEKpYBwP6LKpCUYVTNHSg+2UZ9GTdcJHdjtzqwIh
 TAkkM7/z/YEZebQXpuuHMAP79+u1PCyEpLLiv10LlTrGsN3n8Hz1JJezr8p9LwNfhJfRC+uKDlr
 ZpaLY+X0CpIQ0FnFqgrIYMyLlm//P+w3hVJJveFnn9AOb6ylWiJxNoREeKr16sWgTassOPv7ngT
 4CY2n/559U6BTW5G7iSbDlWohGWVo0EE+5ffuu2GZSr7JQr6m3FaruD9gOefIA0k89UHyg1dw7f
 zLLzJeYKVjvFhi76gwK/Ek+JFzV7/Nw6G+77iOTgtCk2YuV79iKFXwpn0RQUzFk3hUTI6aeXcuI
 CXNS77L2XgwCAXFmt5MGq0n1pgILXLCaoGKcKGoW4NtnagpeXPl1RETZu0q0WhIZaBPSQnJjY9p
 LDFbM71z6ruTaOw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Introduce Samsung AMB630QY01 (Google Pixel 3 XL) panel.

Includes refactoring and improvements to the S6E3HA8 DDIC which is also
used by Samsung S9 (Korea version).

Patches 9 and 11 switch to the new compatibles, so they must not reach
the qcom tree before the driver patches land.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Rebase on top of next-20260923.
- Cosmetic fix s/Cosmtetic/Cosmetic/ fix in the commit msg. (Neil)
- Link to v1: https://patch.msgid.link/20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz

---
David Heidelberg (11):
      dt-bindings: display: panel: s6e3ha8: Adjust to reflect the DDIC and panel used
      dt-bindings: display: panel: samsung,s6e3ha8: Add AMB630QY01 panel
      drm/panel: s6e3ha8: Really assert reset on the failure
      drm/panel: s6e3ha8: Introduce AMB577PX01 panel compatible
      drm/panel: s6e3ha8: Prepare for supporting multiple panels
      drm/panel: s6e3ha8: Correct the polarity logic within
      drm/panel: s6e3ha8: Assert reset GPIO in unprepare
      drm/panel: s6e3ha8: add Samsung AMB630QY01 (Google Pixel 3 XL) panel
      arm64: dts: qcom: sdm845-samsung-starqltechn: Update panel compatible
      arm64: dts: qcom: sdm845-google: Move panel pins into common
      arm64: dts: qcom: sdm845-google-crosshatch: Add display panel

 .../bindings/display/panel/samsung,s6e3ha8.yaml    |  46 +++-
 .../arm64/boot/dts/qcom/sdm845-google-blueline.dts |  18 --
 arch/arm64/boot/dts/qcom/sdm845-google-common.dtsi |  16 ++
 .../boot/dts/qcom/sdm845-google-crosshatch.dts     |  60 +++-
 .../boot/dts/qcom/sdm845-samsung-starqltechn.dts   |   4 +-
 drivers/gpu/drm/panel/panel-samsung-s6e3ha8.c      | 304 +++++++++++++++++----
 6 files changed, 367 insertions(+), 81 deletions(-)
---
base-commit: 3d7783543c2646af69ad65825e810060494bea21
change-id: 20260801-crosshatch-panel-06ce8a69fb7f

Best regards,
--  
David Heidelberg <david@ixit.cz>

