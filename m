From: David Heidelberg <david@ixit.cz>
Date: Thu, 08 Jan 2026 23:13:01 +0100
Subject: [PATCH v4 1/2] doc: board: qualcomm: document Pixel 3 / 3 XL
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260108-pixel-config-v4-1-76a2212b69a5@ixit.cz>
References: <20260108-pixel-config-v4-0-76a2212b69a5@ixit.cz>
In-Reply-To: <20260108-pixel-config-v4-0-76a2212b69a5@ixit.cz>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de, Petr Vorel <petr.vorel@gmail.com>
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, Simon Glass <sjg@chromium.org>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Matthew Croughan <matt@croughan.sh>, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>, Simon Glass <simon.glass@canonical.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1672; i=david@ixit.cz;
 h=from:subject:message-id; bh=hNetKZ+Gddro+OaLlOoaiaAKLTKqtCw0Cv7t5elrvAA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpYCvtYbVwQVtX+//qbGMJliHa2ykjFvvx2GxPy
 N+SZitDgTOJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaWAr7QAKCRBgAj/E00kg
 cuk6D/4wZIi16z6PBPdae34tlgM+74SrAsyIUMD7N+WVNOYVe3DJDXSNCuAa6EbIKEvOlxBJr/d
 xVLk85zYTcvKrwAOXYS9BMITx4gbhukMJgfNdbDsI2F+a/DXt5V8qfPRCe9+G93fuh7/A51LcvF
 7d83wFF/HLcWYEq5FLW/SgCdKK3RrfqoXXlmBb8aTGHGldFocy9wfvJcBDNGXO5VJgHyQQwkleg
 bWA90TLluAPrIcdamZFRZ/XdZ2HGbkrwfPx3tCXCNuNUYce7GebZ2W8ijJiCjVjec5/gL686T11
 gbEzETCuIm0nkUAmw2AUc518lJphaisnY8pXyPf5dWE2/4in6pNKmqEAF09S4VYSJDnuZiu3hvI
 XQjvzgkLTH/DdD9CqoXvsKF8z8j3qlVa/zoqMTsUDOqiVJna3CTzCftHqSGc5UmW0FHhWZqq2GG
 2dWmyjJ6kVvhw+547GWyD2DjB4SJaqNJOC6syEGRvQOVyqpYedMhFXAndZOwp/rTA+cSxH3yceL
 briG5wEYONjnTs3mk0j9Se6kMYS+4lBGCbSaHrNKV818OZUCQfFRnCR7zehgq0eb7NguK9afip6
 dZdFVgGinZ6oH8vJ5IoZGY0U+dxUONl3DKhTWhe7BMmXfTVjeUA+vGbpDcXu3j3ukeykhn6NhX6
 +pTX9/cOUleSabw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

U-Boot does work on Qualcomm 845-based Pixel 3 and 3 XL.

Reviewed-by: Simon Glass <simon.glass@canonical.com>
Reviewed-by: Casey Connolly <casey.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 doc/board/qualcomm/board.rst | 20 ++++++++++++++++++++
 1 file changed, 20 insertions(+)

diff --git a/doc/board/qualcomm/board.rst b/doc/board/qualcomm/board.rst
index 642c5095261..e5dbc9816b9 100644
--- a/doc/board/qualcomm/board.rst
+++ b/doc/board/qualcomm/board.rst
@@ -38,6 +38,25 @@ with appended dtb, so let's mimic linux to satisfy stock bootloader.
 Boards
 ------
 
+Pixel 3 (blueline) and Pixel 3 XL (crosshatch)
+^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
+blueline refers to the Google Pixel 3, and crosshatch to the Pixel 3 XL, both
+powered by the Qualcomm SDM845 SoC.
+
+These devices use the common qcom_defconfig with the google-pixel.config
+fragment for configuration.
+
+Use the following commands::
+
+	make CROSS_COMPILE=aarch64-linux-gnu- O=.output qcom_defconfig google-pixel.config qcom-phone.config
+
+The DTB is called:
+
+ - "sdm845-google-blueline.dtb" (Pixel 3)
+ - "sdm845-google-crosshatch.dtb" (Pixel 3 XL)
+
+More information can be found on the `Google Pixel 3 page`_.
+
 starqlte
 ^^^^^^^^
 
@@ -131,5 +150,6 @@ Other devices with boot image version 2 can be built like this example::
 	fastboot flash boot boot.img
 	fastboot erase dtbo
 
+.. _Google Pixel 3 page: https://en.wikipedia.org/wiki/Pixel_3
 .. _Samsung S9 page: https://en.wikipedia.org/wiki/Samsung_Galaxy_S9
 .. _DragonBoard 845c page: https://www.96boards.org/product/rb3-platform/

-- 
2.51.0

