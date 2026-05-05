From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/4] drm/panel: Small Kconfig cleanup
Date: Tue, 05 May 2026 15:53:39 +0200
Message-Id: <20260505-panel-clean-up-kconfig-dep-v2-0-9cc31d6e6919@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGP2+WkC/33Nyw6CMBCF4Vchs3YMDBeRle9hWJQywERSmhYJS
 nh3K4lbl/9ZfGcDz07YQxVt4HgRL5MJQacI9KBMzyhtaKCYipgoQ6sMj6hHVgafFh96Mp302LL
 FS6vTq07zhLsSAmAdd7Ie+L0OPYifJ/c6vpbku/7Y4h+7JBhj01CpKM3zJtM3WWU+6zfU+75/A
 GKDFPTCAAAA
X-Change-ID: 20260224-panel-clean-up-kconfig-dep-7dc39c351ef8
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Dmitry Baryshkov <dmitry.baryshkov@oss.qualcomm.com>, 
 Dzmitry Sankouski <dsankouski@gmail.com>, Sam Ravnborg <sam@ravnborg.org>
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 marijn.suijten@somainline.org, dri-devel@lists.freedesktop.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=943; i=david@ixit.cz;
 h=from:subject:message-id; bh=MbsyeMNKYIHibIfXf1Ma1pukBf7tKBEWboyL+coTAso=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBp+fZl8i403QHqHgEIls8ya/jXR0LWM8Q0HNtaf
 /oqtzVYCj2JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCafn2ZQAKCRBgAj/E00kg
 ckQ2D/9EnhPxlv+NYhIRGRgVKY5SMfZ+dRHpe4jw2a5uz3Px+SnVd/dpaWqSoo09xWcBQXyIoDY
 N1+H0zarBdgmKYog1mLYjxOl7o0sPVbJRyNJXM/m9nV3o/PCPrAN7wCZUIkPPgeNNVvfyatxmYe
 wCyQd0RvGSOCQKCFOrNFNNM33Q2Dy0KQeSNrsRitfY9IfsIyiyw5PrqWaZPDULLOu9/SSXZL8Ed
 /6EZz/U5Cryrki4rhxDFe82AbJRFhUQU708K/YBaIStHs3+1YaRT/sg09GfvdduLwf5NC/cdLQV
 Us/q3vhvWzhBRwUnvspVU2hIKzPSQzmj0nwjhYfgOwzTPhVOry5DaYGYnLzGbAChpshvW0sxr2x
 bonROVP201LndYtPrIeD4It8g/eGQxyrYwiOYnzj2JKA7/BSDAZ0KhaGjHyXbB7BZfziV8ZUwXv
 JlepQE/6r11Mf+29ZWS5XDp2EJmb8yIpo+RMlJybvshirY5SCYp6eD9gUvepfD7izb9BRWQWCd5
 tAP1WCKDFOrjuoim87sTNqWH7t0tPoIiGwS74jdp3Jmpz9Y6oFR8TDcGNShHwWG43wncNUCw920
 AHsWrwDiP7qEXAP4Ldpq2ezzvE5PtJWo64GGFj+dLBpA2LQB7TYsfaHniZ4VFFRqenl0SzvVwa7
 8uYZ8aYg2a4lNiA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Inspired by looking at Marijn patch. Since Marijn patch is not merged yet,
appending patch to my series.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Split OF from GPIOLIB as these are unrelated. (Neil)
- Link to v1: https://lore.kernel.org/r/20260226-panel-clean-up-kconfig-dep-v1-0-bb28a2355b4c@ixit.cz

---
David Heidelberg (3):
      drm/panel: Clean up S6E3FC2X01 config dependencies
      drm/panel: Clean up S6E3HA2 config dependencies and fill help text
      drm/panel: Enable GPIOLIB for panels which uses functions from it

Marijn Suijten (1):
      drm/panel: Clean up SOFEF00 config dependencies

 drivers/gpu/drm/panel/Kconfig | 24 +++++++++++++++++++-----
 1 file changed, 19 insertions(+), 5 deletions(-)
---
base-commit: 7fd2df204f342fc17d1a0bfcd474b24232fb0f32
change-id: 20260224-panel-clean-up-kconfig-dep-7dc39c351ef8

Best regards,
-- 
David Heidelberg <david@ixit.cz>

