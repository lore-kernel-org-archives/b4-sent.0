From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/3] Xiaomi Poco F1 (ebbg display variant) fixes
Date: Tue, 08 Sep 2026 14:45:01 +0200
Message-Id: <20260908-ebbg-ft8719-fixups-v2-0-5454ae1f5581@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NsQ6DMAxEfwV5rivHAgqd+I+KgQQDXgAlFNEi/
 r0pXTu+O927HYJ4lQD3ZAcvqwadxgh8ScANzdgLahsZmDgnw4xibY/dUtxMiZ1uzzmgdZKlBWd
 kiSEOZy+xOaWPOvKgYZn86/xYzTf96UrK/+lWg4SpFGmeGXJNayrddLm6N9THcXwAEn4yybIAA
 AA=
X-Change-ID: 20260122-ebbg-ft8719-fixups-bce548250b02
To: Joel Selvaraj <foss@joelselvaraj.com>, 
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1011; i=david@ixit.cz;
 h=from:subject:message-id; bh=tggSJCl2AdaSwI6K1UKsXMUFn3nfnZ+dlVIx8qMmy08=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqoANOFJeLQjNYi0kXTpsGdTO+bBpMS+a5Wl0S6
 Nl0RyjUoaiJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqADTgAKCRBgAj/E00kg
 ciBnD/wNSFGRfZVkyBhqNF/AkPwW+A9tFaAfw6x8X3yaefweifSqELEDIH87v+L6N1TSxgj32QD
 RNZ6ocaJEAZge4WV6qcvklwSJcWGlwhWFoBDHnIndBbRudUMIkdZkxvIo1htvE9Wn9Gq7GCsCwY
 mhIRGr05Uba06qS+W0SoZt1jt8U+Y0O9N1AOql3NGNv0qRXD63M8cPh2PYBuOFgcu/nQVOrF3m8
 GNB9GKF5dPRjRfjNB7Yp0pUCX+4OrS1opxeRZ4qZi9pin26icIIoMHBqMV+tz7qY+x5eRNJSL5y
 RmNkl2frVAmm4Apapb120L0gG4Rezu9RS/0hC94pRoRAypz4Ku2ZkhJ/7IlDbgEV8yNu4S0zCyg
 WoRACCzChM1NvHTey88xChBgEzsNleOO1GXjqVvzTNkCnFyNuTqIMDBdmhdM0poX/QGKu5Y4dPX
 F2dXB8APaQPmZssiW72lizk5G84nletKZKvHiPRO/y9M4B4pRzyGmw2cQ86Q+XSADb7Hj7HjZlk
 g3r6G1Dt47ugA8YxFSSvqT+CJH+zhTxcc+DbXHn2+Ein+ejEjocHPVGm1NCIrh6RUmvxULnvBOB
 FkHPEFCE+Z1A61t5ROmhpTKdQwRjALU9ow3HIQD40cy5V2cZLJGGWQbZs0Sfrg4hJxyvbBZljdv
 laqYTedl76R230A==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Been broken in mainline for some time.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Ignore the disable() errors, as there were ignored before too. (Neil)
- Update the `Split initialization into enable/disable fn` commit
  message. (Neil)
- Replaced the maintainer old email with new, so Joel gets notified
  about this patchset being sent.
- Link to v1: https://patch.msgid.link/20260906-ebbg-ft8719-fixups-v1-0-4e846510cad1@ixit.cz

---
Casey Connolly (1):
      drm/panel: ebbg-ft8719: Set prepare_prev_first

David Heidelberg (2):
      drm/panel: ebbg-ft8719: Fix the MODULE_LICENSE() string
      drm/panel: ebbg-ft8719: Split initialization into enable/disable fn

 drivers/gpu/drm/panel/panel-ebbg-ft8719.c | 23 +++++++++++------------
 1 file changed, 11 insertions(+), 12 deletions(-)
---
base-commit: 7079a12d7506b07fb53b54a664bfad5fa9b16d70
change-id: 20260122-ebbg-ft8719-fixups-bce548250b02

Best regards,
--  
David Heidelberg <david@ixit.cz>

