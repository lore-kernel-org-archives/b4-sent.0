From: Massimo Toscanelli <massimo.toscanelli@leica-geosystems.com>
Subject: [PATCH 0/2] usb: gadget: f_ncm/f_ecm: do not notify from set_alt()
Date: Fri, 23 Oct 2026 12:15:26 +0000
Message-Id: <20261023-ncm-ecm-lpm-v1-0-d01e81fbf460@leica-geosystems.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAN5P22oC/yXMSw5AMBSF4a3IHWtSFc+tiEEfF1coaRGJ2Ltic
 Abf4PwXeHSEHuroAocHeVpsQBJHoAdpe2RkgkFwkSdcpMzqmWHYtM7MlMpIybOiyhHCY3XY0fn
 Vmva339WIensTcN8PxY9WdW8AAAA=
X-Change-ID: 20261023-ncm-ecm-lpm-d8bdaa05796e
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>
Cc: Neill Kapron <nkapron@google.com>, Kuen-Han Tsai <khtsai@google.com>, 
 linux-usb@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Massimo Toscanelli <massimo.toscanelli@leica-geosystems.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1243;
 i=massimo.toscanelli@leica-geosystems.com; h=from:subject:message-id;
 bh=I4f84Py9CB+7jlDOXX8Ue6geUC18b5pebZvms0M9osU=;
 b=owGbwMvMwCVmIB2leGXyl1LG02pJDFm3/X9L86mfeyQazpK43/2Fad6/dS+9z/o1rdP+2+67p
 OyzRZV7RykLgxgXg6yYIsu1LeHfI2xzw3Zkda2CmcPKBDKEgYtTACaybDojw/bUtj0xhV7snixf
 j5pOLzZrnRIcoPRR/aqvJ2f0/GVmBQy/WVWfLW74+6nfuit0wTrm0K2FPq3BOrv/P1V4qmT7pCC
 GDwA=
X-Developer-Key: i=massimo.toscanelli@leica-geosystems.com; a=openpgp;
 fpr=D6B457F7583D6D56B86A8AAA301B5A21D493F475
X-Endpoint-Received: by B4 Relay for massimo.toscanelli@leica-geosystems.com/default with auth_id=1289
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

f_ncm and f_ecm queue a notification on the interrupt endpoint already
at SET_CONFIGURATION, when the data interface is in altsetting 0. If the
host loads no class driver, nobody reads it. While data is pending for
the host the device may answer NYET to an LPM request, and DWC3 does,
so the device never enters L1. The USB-IF USB3CV tool fails the
"L1 Suspend/Resume" test (TD 9.21) because of this.

For altsetting 1 the call in set_alt() is not needed: gether_connect()
already notifies through the open/close callbacks. The extra call also
makes the host see two connection notifications before the speed one.

Patch 1 fixes f_ncm, patch 2 makes the same change in f_ecm.

Signed-off-by: Massimo Toscanelli <massimo.toscanelli@leica-geosystems.com>
---
Massimo Toscanelli (2):
      usb: gadget: f_ncm: do not notify from ncm_set_alt()
      usb: gadget: f_ecm: do not notify from ecm_set_alt()

 drivers/usb/gadget/function/f_ecm.c | 8 --------
 drivers/usb/gadget/function/f_ncm.c | 4 ----
 2 files changed, 12 deletions(-)
---
base-commit: bdf12cde30830d46a8ef1ba93986356f1164b4f1
change-id: 20261023-ncm-ecm-lpm-d8bdaa05796e

Best regards,
--  
Massimo Toscanelli <massimo.toscanelli@leica-geosystems.com>

