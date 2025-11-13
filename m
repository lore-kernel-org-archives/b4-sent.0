From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 00/12] Make Samsung SOFEF00 DDIC and panel work
Date: Thu, 13 Nov 2025 18:57:34 +0100
Message-Id: <20251113-sofef00-rebuild-v2-0-e175053061ec@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA8cFmkC/3WNQQ6CMBBFr0Jmbc1Mg8W48h6GBbRTmcSAtoWgh
 LtbceHK5XvJf3+ByEE4wqlYIPAkUYY+g94VYLumv7ISlxk06gMRlioOnj2iCtyOcnMKS+utYXP
 kiiCv7oG9zFvxUn858GPM4fSTncQ0hOf2OtHH/j+YSKFy3vqGKm6pMmeZJe3tC+p1Xd9ajmIGw
 QAAAA==
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
 Casey Connolly <casey.connolly@linaro.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2543; i=david@ixit.cz;
 h=from:subject:message-id; bh=vgzmso7a8Y8t5RJ9ImlUQnWFBosuuGamKlYy2aDvNqk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpFhwUpLovHkS4Wk+TvhDkWFSO6YdoFELC9NIfw
 X/f4peBP9eJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRYcFAAKCRBgAj/E00kg
 clvvEADM9AA6L1Uc0zOH7Xy9Lg+VvtzTdgFMcacL8oqV0Jxc4xA7uwMogRWbbT6AfveF0nYSWJJ
 +RIpkBqvZ69T6klh61F3hrzhXZqOzy1kKtB65Qnp1ESAJkV1RxjLtV3G+xog7LjtK5roItWeBH6
 SyB6/2PVRijQyrHWy0IEhKjqm0gUy2VmcgX4gecnfKFyBO07+PvNr6AkIDj0cIY550VezG5OjxD
 3zrqxMGKvE/+d79+pekZqZsK7hjHLW1FIPNu2GfAH8qQBuWTFsEgecLdJWCz+PdFZwan2JaNDa0
 BE8XIw6GgXrPm2p+LyapG2h2rOj1JTm+GGs0L6GgcILpNoS1jym8eHxvErn1Lmu1ZpFgXsWRMIN
 1hPjN3F6feAMRmfce/iuJ3Pl1EI9trHYqtVfpy+T0IRCdkNyZ11oo4jcwPL02Dbj0z14vJYWzPb
 vLMrqmme9zrCal67ZrmZpux/vY27ZTjls+k5YCBM9F6ZefEzs/vS43O+Mg8ayntl+Sw59bbsiNX
 AG94WO0ZaBOMM/iE/wcb7puT1l8OSr1zu6NpOBArQidVFaOMjAjokTjJA+58uSYFvGG6ingKAaA
 KJhrkSKaLJECwKAYNIZMRlLyiXmFEFhJhC3gfVRDjRdF4h0dXQi11/+w3RIHrrk8raKhb9ZJOfh
 8A9sYHFcvnHLQFw==
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
  https://gitlab.com/dhxx/linux/-/tree/b4/sofef00-rebuild

There are some unknown issues with -next-20251103 - 11, so won't likely
work there, recommend linus 6.18-rc4 and later.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
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
      arch: arm64: qcom: sdm845-enchilada: Specify panel name within the compatible
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
 MAINTAINERS                                        |   6 ++
 .../boot/dts/qcom/sdm845-oneplus-enchilada.dts     |   4 +-
 drivers/gpu/drm/panel/Kconfig                      |   7 +-
 drivers/gpu/drm/panel/panel-samsung-sofef00.c      | 104 +++++++++++++--------
 6 files changed, 162 insertions(+), 63 deletions(-)
---
base-commit: 6d7e7251d03f98f26f2ee0dfd21bb0a0480a2178
change-id: 20251104-sofef00-rebuild-04cfc6e68e71

Best regards,
-- 
David Heidelberg <david@ixit.cz>

