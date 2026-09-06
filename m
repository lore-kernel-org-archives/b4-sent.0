From: David Heidelberg <david@ixit.cz>
Date: Sun, 06 Sep 2026 15:19:03 +0200
Subject: [PATCH 2/3] drm/panel: ebbg-ft8719: Fix the MODULE_LICENSE()
 string
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260906-ebbg-ft8719-fixups-v1-2-4e846510cad1@ixit.cz>
References: <20260906-ebbg-ft8719-fixups-v1-0-4e846510cad1@ixit.cz>
In-Reply-To: <20260906-ebbg-ft8719-fixups-v1-0-4e846510cad1@ixit.cz>
To: Joel Selvaraj <jo@jsfamily.in>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sam Ravnborg <sam@ravnborg.org>, Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 Linus Walleij <linusw@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1192; i=david@ixit.cz;
 h=from:subject:message-id; bh=K+6x5A7ftBFeZ8okSqt/u0WpvagsMUKZ/4i4XfBmirE=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqnWhQKxw/18Yi3JTzGNeX5AKT86t+qacac3fYZ
 YrXf92tobCJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCap1oUAAKCRBgAj/E00kg
 cqHbEACUzO5xpCO6DJHKL+wZE4cGM0+6FVzSI2CJiTlBmx7ivsSVlVTUm9VzMpRoGmMoPmep8mx
 jk+g02tU1yTP1uoMxWxLsN1BGU6v42Yelh3j3h8t0T/Cwi/HsYSuZXE07fG9EErm1QZoe/lugHI
 jf8WfnXlQy/2rcadTEYH5huYkCyFmQ6dHZ4kt2LBidufQ+P603p8b+tqX5IfkN/Zl2ZMJReyPev
 2D1RgK3VGbH0euiZXZPh9ukLP/kM5fVzAaYfbVGzNP5Hm7Tj5GL18ZUtMuPsgfToPSxwHIgagYR
 COdrUowbB7a6aJHZ92j1b7G9bSz2UODSzPys2c02J705RWqU0/lCfQBL2wuvlO4hMVN79yAsHW+
 jsynWFbsb0gWjkn6HLi3AEVGLtIQULjbCiQp7JIdcaRGput6HEp8+si02v8OJVGmR0d+mYHpFpt
 eqyvezPNajC2GDVPFTNCPFpNy6VnZn0AcsYKs86cR4Xv6Vt8IzF/zyVceSHZ1Hf7gUs6cTUUuSI
 Vpuj2srixPiX/6oWFubE0N1BzhClsJ7sTIgnmYGIbn7iNGPyk3qoPPwvjNPURDlgsFLOdZPboup
 7fFgqJ2duCnQZApnt+1sfIzL67YANFVfiMn/pkWq54ohlBO8JwUD2kRn0ttMWBMJVKZsPA/CFC4
 zNaES1kh101L4AQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the bogus "GPL v2" with "GPL" as MODULE_LICNSE() string. The
value does not declare the module's exact license, but only lets the
module loader test whether the module is Free Software or not.

See commit bf7fbeeae6db ("module: Cure the MODULE_LICENSE "GPL" vs.
"GPL v2" bogosity") in the details of the issue. The fix is to use
"GPL" for all modules under any variant of the GPL.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/gpu/drm/panel/panel-ebbg-ft8719.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/gpu/drm/panel/panel-ebbg-ft8719.c b/drivers/gpu/drm/panel/panel-ebbg-ft8719.c
index 1ab09c50a6306..14982263a94f1 100644
--- a/drivers/gpu/drm/panel/panel-ebbg-ft8719.c
+++ b/drivers/gpu/drm/panel/panel-ebbg-ft8719.c
@@ -241,9 +241,9 @@ static struct mipi_dsi_driver ebbg_ft8719_driver = {
 		.name = "panel-ebbg-ft8719",
 		.of_match_table = ebbg_ft8719_of_match,
 	},
 };
 module_mipi_dsi_driver(ebbg_ft8719_driver);
 
 MODULE_AUTHOR("Joel Selvaraj <jo@jsfamily.in>");
 MODULE_DESCRIPTION("DRM driver for EBBG FT8719 video dsi panel");
-MODULE_LICENSE("GPL v2");
+MODULE_LICENSE("GPL");

-- 
2.55.0

