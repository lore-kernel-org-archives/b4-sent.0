From: David Heidelberg <david@ixit.cz>
Date: Wed, 07 Jan 2026 21:28:15 +0100
Subject: [PATCH v3 1/2] doc: board: qualcomm: document Pixel 3 / 3 XL
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260107-pixel-config-v3-1-02a25e3fdcfa@ixit.cz>
References: <20260107-pixel-config-v3-0-02a25e3fdcfa@ixit.cz>
In-Reply-To: <20260107-pixel-config-v3-0-02a25e3fdcfa@ixit.cz>
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de, Petr Vorel <petr.vorel@gmail.com>
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, Simon Glass <sjg@chromium.org>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Matthew Croughan <matt@croughan.sh>, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1561; i=david@ixit.cz;
 h=from:subject:message-id; bh=tR/yDcGYe9KsmThFZVe68c8YKtFLwect8VpgVOCqg3g=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpXsHgrGbQl1CKKnlCPl9/w8vSdapSI0bgUT92Y
 YkGVkR/pT+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaV7B4AAKCRBgAj/E00kg
 csDCEACdzHGycxGA/+CFDj/RO2QxjSgtZWDoz1U0Pdq2WCwLzeuGMZDr3/g/Lv3p+V90sgbnqk+
 2TUZPGIhJcjXyfrCyqp4JQ4PbBDZTGOr38qwYbs/dfKN32JTGe5rX5+5EaJOMQJ5TU8VP+HwBki
 r2G8hEe9n6lEe2inIMkI8/igivB91P6KyZG/9IPHv6IoGE34caaMBG7a/fJJw01CmMyPcpp/2jV
 a3Yigoveorjz0VIJFYim/mE4tysM2OPrMntqOkDuf3WQfOyGkiXy24padsO/qocUIy2FZOJen4v
 xPoJcY2rNXXTM8BA1t5rYj4H3ldtDYFTm5qp99H/cR+fL5hkUJ1B9F2xN08cyN50eXhMW04VCjN
 bd/6W+jjOrmqVpoVSuQIgSXP9qybfPGwdxlG8hB68cba2KPL140ZPHrjlb+9U0qjbQrYB7vNJpW
 d1GasNklvSVQ0cla6CmOHDmV7PKjm3Mu/ByowxshTt4kLxMEcqeANIP0kY+BGlcJBHlQR398Xa8
 jt25OteAUYiEc0zel9/9gYj+3ygVO20+MlD2xqT3lG2bDCpm2XCRAtKISA9iLH9+02du+HHRSt9
 zlyquMVwoqgnT4S+SaGadHIHSWClgUEcS0HFeHFU8BnRRQd+Gl2tEiM2lSLAaUs9mo69ULn8TPq
 rSrUaJUTDhTKtXg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

U-Boot does work on Qualcomm 845-based Pixel 3 and 3 XL.

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

