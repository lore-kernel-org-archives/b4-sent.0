From: Marian Poltak <marianpoltak@gmail.com>
Subject: [PATCH bluez 0/2] shared/gatt-client: Fix init when Service
 Changed lacks Indicate
Date: Thu, 12 Nov 2026 18:40:52 +0100
Message-Id: <20261112-svc-chngd-notify-only-v1-0-c7db7ac47acf@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MwQqDMAyA4VeRnA0sVQb6KuLBNakGJJV2kznx3
 Vc8fof/PyFLUsnQVyck2TVrtAKqK/DLZLOgcjG4h3sSkcO8e/SLzYwW3xoOjLYeGIiJu46b0LR
 Q2i1J0O/9HeC1fuQH43X9AU98HdRuAAAA
X-Change-ID: 20261112-svc-chngd-notify-only-f1d1d99d3f34
To: Linux Bluetooth <linux-bluetooth@vger.kernel.org>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794505252; l=923;
 i=marianpoltak@gmail.com; s=20261112; h=from:subject:message-id;
 bh=A66skHcAAlDfhvBqoejBHvaNOhKROvLL9YnYeX/oPI4=;
 b=eq5rpINfsdVrWv+ryg9t6cZl0lvGMi3CaZGG6MXfCcDKMd2EvKJVzjD9jGlazGuwCiutaJjFN
 gJS62XMtZ9zBTqPCLp4ims6qslSWWw9wyfyWtQT60yse+Gg4Eol7eoK
X-Developer-Key: i=marianpoltak@gmail.com; a=ed25519;
 pk=VPxSnAMaNkyjfVbKo8tQ1gFPwqOoZoPqtVZ8znSiAiA=
X-Endpoint-Received: by B4 Relay for marianpoltak@gmail.com/20261112 with auth_id=1502
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some devices, e.g. the Aqara Presence Sensor P2 in Matter commissioning
mode, declare the Service Changed characteristic as Read | Notify only.
The client initialization then fails because indications are requested
explicitly, so no services are exported although ServicesResolved is
set.

Patch 1 requests indications only when the characteristic supports
them. Patch 2 adds unit tests for both cases.

---
Marian Poltak (2):
      shared/gatt-client: Fix init when Service Changed lacks Indicate
      unit/test-gatt: Add Service Changed registration tests

 src/shared/gatt-client.c | 15 ++++++++++++++-
 unit/test-gatt.c         | 39 +++++++++++++++++++++++++++++++++++++++
 2 files changed, 53 insertions(+), 1 deletion(-)
---
base-commit: 9659adb6819d7e0284d0d2ba226a3894423d8db4
change-id: 20261112-svc-chngd-notify-only-f1d1d99d3f34

Best regards,
-- 
Marian Poltak <marianpoltak@gmail.com>

