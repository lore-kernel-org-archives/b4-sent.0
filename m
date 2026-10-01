From: Miao Wang <shankerwangmiao@gmail.com>
Subject: [PATCH RFC v2 0/4] gpio: loongson-64bit: add interrupt support for
 more models
Date: Fri, 02 Oct 2026 02:13:18 +0800
Message-Id: <20261002-loongsongpio-v2-0-6e3eb150a4ef@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAL+ivmoC/1WNzQrCMBCEX6Xs2Uiz2qTtSRB8AK/SQ3/WdKFtS
 iJBKX13Q/DiYQ4zw3yzgSfH5KHONnAU2LNdosFDBv3YLoYED9ED5qjyCgsxWbsYH7WyFSVWJZ7
 b01AohDhZHT35nXAPuN+u0MRwZP+y7pMugkzVj6b+aUGKXGg5kKaOuk6ri5lbno69naHZ9/0Lk
 HguGK0AAAA=
X-Change-ID: 20260925-loongsongpio-829824a3d562
To: Yinbo Zhu <zhuyinbo@loongson.cn>, Linus Walleij <linusw@kernel.org>, 
 Bartosz Golaszewski <brgl@kernel.org>
Cc: Jiaxun Yang <jiaxun.yang@flygoat.com>, linux-gpio@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Miao Wang <shankerwangmiao@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1435;
 i=shankerwangmiao@gmail.com; s=20250715; h=from:subject:message-id;
 bh=jk9WrNQmxQdqtC1QZp9FtvvRcQ5EK8qJVsNHKLYcB4M=;
 b=owEBbQKS/ZANAwAKAbAx48p7/tluAcsmYgBqvqLfOtk3ZZLskew3wfMsPMJh+Hn9vAZnFdMAI
 cRp3gIicl6JAjMEAAEKAB0WIQREqPWPgPJBxluezBOwMePKe/7ZbgUCar6i3wAKCRCwMePKe/7Z
 bkdqEADUsiQ0n53zh23dlMfmWYZfUChZTO4wroE07UZNHv0Bgag3j3DQAajpmT6UquoTPudMvuK
 oxzZm6jEEpLc3ZEXhfDmE3cB0UPGOogCI/zuFNWf/w678xfIHSiQ44ebmffTpUThO94bPR/675B
 f9AKnLGracMi0mrm9eRX4mpjPER7V8b7/nDnuUkCvSahfVakPnSjkze3+itsGQMyQYmx8FCMxG/
 YYy1lKtWDKNgGBhXcswxg2IP8ps2Feh4lnpLfN55e6JtvNpVn1ax2q9VGYlh5JpWCy9Cb0nn2iZ
 V3/qAEmwTZMA+CCTK3rzmFXFP+Oes3j25G56wBt71i2zmFGI6QkwLKwxwYbCdahdkL1o4gHnWzM
 WmzZnBUbwjPUmFL3iTgAEubFj/+2TPRiTPuY2bAlT91v5vDvjkqm8J/LUXvh5X2SfWlJE2vfQEL
 QV+sEY311Y2SVL+h70EcGjrBWk3qy2q/StxW9unoMOtf2hsyBRCkJczHYu08VC6hYjcBhuMGMxK
 /6xuXo+yo1+ff/KDYGXPiEnPrLj3GPkmz/68SW/acHv9FZWIIBl3Db7Rqx+Eg2cP36vq0LmiF6B
 5V1ig9jolVICO/WbMeTFtvtyvfyKW2rLJEF8oMwvX8nqG19tGGbB6u/M/i47q/xIhEwGnaqFK11
 UpufhxxRceYKMig==
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
Changes in v2:
- +Cc: linux-kernel, as required by Bartosz
- Shorten the names of struct members to increase code readability
- No other significant changes
- Link to v1: https://lore.kernel.org/r/20260926-loongsongpio-v1-0-71de7ebebb76@gmail.com

---
Miao Wang (4):
      gpio: loongson-64bit: Support for irq controller on 2k2000 and 7a2000
      gpio: loongson-64bit: Generalize interrupt controller initialization
      gpio: loongson-64bit: Add shared interrupt support
      gpio: loongson-64bit: remove gpio_to_irq() handler

 drivers/gpio/gpio-loongson-64bit.c | 706 +++++++++++++++++++++++++++++++++++--
 1 file changed, 681 insertions(+), 25 deletions(-)
---
base-commit: 481ed5dd3ed7136f627b8ec372ba39f5b2e7d27f
change-id: 20260925-loongsongpio-829824a3d562

Best regards,
-- 
Miao Wang <shankerwangmiao@gmail.com>

