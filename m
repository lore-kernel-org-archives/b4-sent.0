From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH RFC 0/4] gpio: loongson-64bit: add interrupt support for
 more models
Date: Sat, 26 Sep 2026 00:28:35 +0800
Message-Id: <20260926-loongsongpio-v1-0-71de7ebebb76@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADOhtmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDSyNT3Zz8/Lz0YiAuyMzXtTCytDAySTROMTUzUgJqKShKTcusABsXrRT
 k5qwUW1sLALMPZFBjAAAA
X-Change-ID: 20260925-loongsongpio-829824a3d562
To: Yinbo Zhu <zhuyinbo@loongson.cn>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: Jiaxun Yang <jiaxun.yang@flygoat.com>, linux-gpio@vger.kernel.org, 
 Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1176;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=XzL7Uv8CKAnxpcOUO6KGyIQeIGCAlJYhjueKwobecP8=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqtqE2JujRZUCyC6KX9QaiH2qAoWySkeDG5n9Ds
 6tikP123AWJAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCarahNgAKCRCwMePKe/7Z
 bg4DEACUXZQYjwzsQM0NCgYvsKPlPWuNhNA1DFLA51kocQYra3b+e6TDYQchzJPKIodRpZztaiZ
 sfnmNbj6my3pB3kTt/t6Z0icri5osvY8suxJCjcfxX9qUzb+pZ52C2gB6F0O8m78WIAyy20W2nx
 gDCZ6lcuidr3ZklrvAGuaw00CLrhafjakTr3ZfATUj+6ah1XomLI69Y35MitCtrUlEYWuaZCtJ2
 I5AbS5s1I/pmuqPSWYXHrWZtrh1aJoCNbrY4oEuYUoiG2S2KY4D+dYyj8k6CByLONK3wpsMxJrh
 QIhQAtRBQuv2Pa9rqxFdUu3odB8s4mB+qaCSoQcsSi6QmDsV7RCPj/IQRFYe/Y6yLrV7hQkchmW
 dksRL201pXxPy8ppdO5BsKNmI4lEhQrTdcY6nOPYDPGnSfj2ea2QimVrF1XXqFzcgM7DNiBI0e4
 rJubbht0Ck4r7kzu+fi6kFnUTtyDysbPnlw04R4lEZNwnARkuFqxwCxfVm8d6PUNNGRSwPDUwSh
 xqlY7CbE/VlUFrFT3Q674kNQGbUVT9PiOfBfzhqxVuvkHzHhooONRnQCYuiWFo4D2CoUgYx/WgZ
 BSXcfnxXVb+DlYTeHf+oG0oZexmBeSefgj0T2sfavXGsZ2mZrD4l+sWlCScmdOwRSpxG9UBONmm
 bNPCzIpRC0QRNHA==
X-Developer-Key: i=shankerwangmiao@gmail.com; a=openpgp;
 fpr=6FAEFF06B7D212A774C60BFDFA0D166D6632EF4A
X-Endpoint-Received: by B4 Relay for shankerwangmiao@gmail.com/20250715 with auth_id=462
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patch series aims to correctly add interrupt support for GPIO
controllers found on more Loongson CPUs. The GPIO controllers in such
models do not have a complete intgrated interrupt controller, but choose
to delegate interrupt handling to their parent interrupt controller.
This sounds like a heirarchical interrupt setup, but what makes it
more complex is that multiple GPIO lines in these controllers may share
one interrupt line on the parent interrupt controller. The details is
described in the third patch.

Signed-off-by: Miao Wang <shankerwangmiao@gmail.com>
---
Miao Wang (4):
      gpio: loongson-64bit: Support for irq controller on 2k2000 and 7a2000
      gpio: loongson-64bit: Generalize interrupt controller initialization
      gpio: loongson-64bit: Add shared interrupt support
      gpio: loongson-64bit: remove gpio_to_irq() handler

 drivers/gpio/gpio-loongson-64bit.c | 708 +++++++++++++++++++++++++++++++++++--
 1 file changed, 683 insertions(+), 25 deletions(-)
---
base-commit: 481ed5dd3ed7136f627b8ec372ba39f5b2e7d27f
change-id: 20260925-loongsongpio-829824a3d562

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

