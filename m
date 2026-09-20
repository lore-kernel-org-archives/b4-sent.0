From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 00/11] Pixel 3 XL display panel support
Date: Sun, 20 Sep 2026 13:05:43 +0200
Message-Id: <20260920-crosshatch-panel-v1-0-de6e9512da96@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMwQ5FMBBA0V+RWWtSFn34FbGoMdURKekgEvHv6
 lmexb0XCEUmgSa7INLBwktIKPIM0NswkuIhGUpdGl3pQmFcRLzd0KvVBpqVNkiVNbXrfw5StkZ
 yfP6XbfdZ9n4i3N4P3PcDWZWJPnQAAAA=
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
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1752; i=david@ixit.cz;
 h=from:subject:message-id; bh=EJWkMZMekiOD8WaCohx4ypgSL1x/M1fKD7fZsYIwGLI=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqr74I+wMXsFX69qUr3dPQUtBnc4sv57WrxTS+T
 EHXLku8qXiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaq++CAAKCRBgAj/E00kg
 clCFD/9WKcjRK5+Yp1wtDtfJ+l8NacQx+caBsWGCQzUEvfwQr2mm5wN0x24T/OBkQwMLKdKsGRM
 Mwt+5BSV8AE4+TH+IQxAANqrLfFCURPJ+FIPHF4+BPLcnQBS/vk7Vq7HskZ6X/AdZqZfyZHghHx
 dSLLYpEe5MtLBf/x0r8XeaKv7UUlLPaCDjkTmF5P7Kdsg+nhJOWXP3htiAi/vk8qDp3XjI1Awvu
 6/4Fmcu0pLXgB2aasjt35SZfXb62xKDCz31Mimotd5emBbexycOWvJMZ4rnF+nxb8S5dsP7wKGg
 N2b1OvSt/VdWDaTCdp5eRFYDAxLN2A76XL7nVyMiyMj9KksGpdfsXcKLo4eWN+WPuN9mpDjzPuc
 cVWYXMH0SPFrKav+IeNRCRJbcsDbnwwmHBJ8rFZ5hq1Frmzc9/pZLJJCSLDpz5oa5hQOIThYb/w
 LTuYaN/E1QwG00nzfhfuOpiRWpsacxosi4g2/ct2BJcyDK/AFiDci8W+H9ZJ077AvORmBRDQQku
 KXtZd+KeiUFxagfbboVdfcmuuGUxAetpcgm9cCEdmrwiZsp2vRJ9zS9CrIRtf6wohi81XD8Y8kf
 JM5huXnW+4IqZKOWUHEL49W3r77Lx5IW9Rza40pzOmfs3bp0BFTZlHN/tBSiKpZxXxQZPbkdhfg
 ZV5vcsV6PN/S3Ig==
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
base-commit: 3f2425f5b5bbbdd991ca9cdfd5502e68d8895998
change-id: 20260801-crosshatch-panel-06ce8a69fb7f

Best regards,
--  
David Heidelberg <david@ixit.cz>

