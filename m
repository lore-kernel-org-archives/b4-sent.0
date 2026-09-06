From: David Heidelberg <david@ixit.cz>
Subject: [PATCH 0/3] Xiaomi Poco F1 (ebbg display variant) fixes
Date: Sun, 06 Sep 2026 15:19:01 +0200
Message-Id: <20260906-ebbg-ft8719-fixups-v1-0-4e846510cad1@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x2MywqAIBAAfyX23IIuPaxfiQ5Zm+3FRCuC6N+Tj
 sMw80DiKJygLx6IfEmS3WfQZQHzNnnHKEtmIEWN0kTI1jpcD9PqDle5z5DQzlxXhmplFUEOQ+R
 s/ukwvu8H1f1homQAAAA=
X-Change-ID: 20260122-ebbg-ft8719-fixups-bce548250b02
To: Joel Selvaraj <jo@jsfamily.in>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 David Airlie <airlied@gmail.com>, Simona Vetter <simona@ffwll.ch>, 
 Sam Ravnborg <sam@ravnborg.org>, Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 Linus Walleij <linusw@kernel.org>
Cc: dri-devel@lists.freedesktop.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>, 
 Casey Connolly <casey.connolly@linaro.org>, stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=629; i=david@ixit.cz;
 h=from:subject:message-id; bh=nvyihE17l+ORxYrEI+2u0xDHs4DHHPvWAuMH2VNNS00=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqnWhPbx8vOR2yaGpvwMlaKW+s7YDfp9h0MCAvW
 FVn8Yx7fo+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCap1oTwAKCRBgAj/E00kg
 cjH5D/9JcSicP7F+mjJ2JommLLfpDtCS/jKb1KHE3bw12u7csi/uLmFfSjNfK3io5v96H8JA5z6
 /PIRLhqrzQMN9RHb9f5byx+rcunUDjNJgIQmxUZAwYFpLIE+HxkNT0x0JvCYy7xzHLRs7U43GIT
 4ZUVAWzJ+IeENr7JiWdI+yMEcT+kRqwa0EHU1A0JHI896yRIjRpKIzaWxUBxX5bZBLSLAL4gvD9
 zn6hZRjA+lfBrO0a/AkkHCw/MkrLN9hE53/lCQdtDxs/miXum0H5XdOUdbtnEndCC+Q631XTnX/
 PCcGG/blI6vdEnZ3/suzQ9fthli5G7oe38jtFZ4Xsiq2FqgzNAY/+7eiGSjNsnE8VrCBVkBDxOs
 L7Za0hakVc28AFqLsKC7mB5nSDbZYJXMeVxN5oAJHzFansysHBLKltj5+ji9jxOWV3T7u3tgyQC
 b/CuhCDAKdZZDGlZ9RZ00hIQVp/AH01BtmrPWvmLpZVWKSkdUrBZmATRoBs4nS9rCqUQVPS3Syp
 A67hk4k8ajrERT3soJzTvmKSVvZ87e+ItecT7qvsAUYIPhjqVFJN7KQu3h8ltY0xHf9kTghG9n3
 8efVwKvJ+pC689BcbPUXnjDnSXM6xyNKmzWaNzifCQuJv2npIe9c8FzYEHncNwgszKzHlupwrLF
 0TKbGRaUYoarUKA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Been broken in mainline for some time.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Casey Connolly (1):
      drm/panel: ebbg-ft8719: Set prepare_prev_first

David Heidelberg (2):
      drm/panel: ebbg-ft8719: Fix the MODULE_LICENSE() string
      drm/panel: ebbg-ft8719: Split initialization into enable/disable fn

 drivers/gpu/drm/panel/panel-ebbg-ft8719.c | 21 ++++++++++-----------
 1 file changed, 10 insertions(+), 11 deletions(-)
---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260122-ebbg-ft8719-fixups-bce548250b02

Best regards,
--  
David Heidelberg <david@ixit.cz>

