From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 00/12] Make Samsung SOFEF00 DDIC and panel work
Date: Wed, 19 Nov 2025 15:21:25 +0100
Message-Id: <20251119-sofef00-rebuild-v3-0-6cd55471e84e@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGXSHWkC/3WNyw6CMBBFf4V0bc1MedS48j+MCyhTmcSAttCgh
 H+34AIT4/Lc5Jw7CU+OyYtjMglHgT13bYR0lwjTlO2VJNeRhQKVI0ImfWfJAkhH1cC3WkJmrCm
 oOJBGEa27I8vjWjxfPuzoMcRwv40N+75zz/U14LL+PwgoQdbW2BI1VaiLE4/c781LLKWgvmxMf
 20VbUKdQ55CgWQ2e57nN9Ax3mn/AAAA
X-Change-ID: 20251104-sofef00-rebuild-04cfc6e68e71
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jessica.zhang@oss.qualcomm.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, Sam Ravnborg <sam@ravnborg.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Krzysztof Kozlowski <krzk@kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2672; i=david@ixit.cz;
 h=from:subject:message-id; bh=30zdp00ssHhIY0HNpB1mEZhkfA29GQGRCgBxkHTNKNQ=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpHdJxCvV6m5YJzmboX2MJ3rsvOYNmpY0I/N9qe
 qp6mD33FnyJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaR3ScQAKCRBgAj/E00kg
 cs+4D/9HKugFefH70tsVLJ0YUo21AB/Lx+KhnQL0uFXMgzIoq5TY+ez5QDGbAKJGRSjX4nBYst0
 Y379l6+hvpaLs3kY2+jNAm2j+IEzF0P/3RXxUNCmv8CBsk1jtMsxcJz1e3uXVU5ShJZYEe70sLa
 puuOi07P4WTzlYtqG8SywmhzPPELdVY2vGD423hFzjSck4cdtNXYsUkUh9bh8voq1/AuLRDmgYP
 P/N6HMOwW79paMyDifuOYSEEw6b76+x4qlcero/t8GNmGd2N3DAEu4iuNZrKssrqd/itMrRcada
 ntcFrwdg2evJ1c+K5rC8Jm93xoJ2YOFTnGU+pB7Ivp1DIQ8nOop2HacvfDVhb/zSkbmi39IMgt9
 Pf02dIQeo80CxqpZCZC7tw6zmwx2LUKerGk4K/eaiDSVQOlAOYQVhCcolj/FMWxtQCg9JJsz3jy
 YN4hWg+L0q8oeYUDtoUWZp9xht0kPo9gLRhkzRoJd9TMLhIckNyo05gmb5UtLNppspjEkMrjBh7
 vcXHseO/ejimV3/ChOChQNGqDjgFRNIM1x3dRoD/D86WRdNGYjnsXofFB4rxyXrdHmuEUH9H4/s
 wXM0WetyjgKmgFO//scrW4GsKOPswleBaVKnfY9wEBjVQ92QHXUgVwFc1Ql7YhITpmJ/zU9sV8o
 1rC845UWm/IW+zw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This DDIC is essential for panels used in OnePlus 6 and Pixel 3a XL
(SDC variant). With proper support, all downstream patches in
sdm845-mainline and sdm670-mainline can be dropped.

The mainline driver was broken so far, and with my recent introduction
of S6E3FC2X01 driver, I had to "break it even more" due to OnePlus 6
common device-tree changes which defined all the regulators and
corrected properties.

At this moment the first version of the patchset will not include
Pixel 3a XL (SDC) as no testers yet volunteered.

The code, including the Pixel 3a XL enhancement can be found at
  https://gitlab.com/sdm845/sdm845-next/-/commits/b4%252Fsofef00-rebuild

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Drop arch prefix from the commit. (Bjorn)
- Added Casey into MAINTAINERS file. (Casey)
- Moved compatible legacy comment inline.
- Link to v2: https://lore.kernel.org/r/20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz

Changes in v2:
- General fixes to device-tree binding (Krzysztof)
- Add myself as a maintainer
- Updated commits wording
- Link to v1: https://lore.kernel.org/r/20251104-sofef00-rebuild-v1-0-dfcfa17eb176@ixit.cz

---
Casey Connolly (2):
      drm/panel: sofef00: Add prepare_prev_first flag to drm_panel
      drm/panel: sofef00: Initialise at 50% brightness

David Heidelberg (10):
      dt-bindings: panel: Convert Samsung SOFEF00 DDIC into standalone yaml
      arm64: qcom: sdm845-enchilada: Specify panel name within the compatible
      drm/panel: sofef00: Clean up panel description after s6e3fc2x01 removal
      drm/panel: sofef00: Handle all regulators
      drm/panel: sofef00: Split sending commands to the enable/disable functions
      drm/panel: sofef00: Introduce page macro
      drm/panel: sofef00: Introduce compatible which includes the panel name
      drm/panel: sofef00: Simplify get_modes
      drm/panel: sofef00: Mark the LPM mode always-on
      drm/panel: sofef00: Non-continuous mode and video burst are supported

 .../bindings/display/panel/panel-simple-dsi.yaml   |  25 +----
 .../bindings/display/panel/samsung,sofef00.yaml    |  79 ++++++++++++++++
 MAINTAINERS                                        |   7 ++
 .../boot/dts/qcom/sdm845-oneplus-enchilada.dts     |   4 +-
 drivers/gpu/drm/panel/Kconfig                      |   7 +-
 drivers/gpu/drm/panel/panel-samsung-sofef00.c      | 105 +++++++++++++--------
 6 files changed, 163 insertions(+), 64 deletions(-)
---
base-commit: fe4d0dea039f2befb93f27569593ec209843b0f5
change-id: 20251104-sofef00-rebuild-04cfc6e68e71

Best regards,
-- 
David Heidelberg <david@ixit.cz>

