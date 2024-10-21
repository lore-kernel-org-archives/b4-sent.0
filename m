From: Levi Zim <rsworktech@outlook.com>
Date: Mon, 21 Oct 2024 21:55:49 +0800
Subject: [PATCH net] docs: networking: packet_mmap: replace dead links with
 archive.org links
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20241021-packet_mmap_fix_link-v1-1-dffae4a174c0@outlook.com>
X-B4-Tracking: v=1; b=H4sIAGRdFmcC/x2MUQqAIBAFrxL7naAWFF0lQsRetVQmGhFEd0/6H
 IaZhxIiI1FXPBRxceLDZ1BlQW6xfobgMTNpqWsltRLBuhWn2XcbzMS32divArIeXYOmrSQopyE
 iu3/bk8dJw/t+KkwZRGsAAAA=
X-Change-ID: 20241021-packet_mmap_fix_link-e04dc7e7830e
To: "David S. Miller" <davem@davemloft.net>, 
 Eric Dumazet <edumazet@google.com>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Jonathan Corbet <corbet@lwn.net>
Cc: netdev@vger.kernel.org, linux-doc@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Levi Zim <rsworktech@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1633;
 i=rsworktech@outlook.com; h=from:subject:message-id;
 bh=Tqm24mciBlPvfXzUkyHHyeW7l0+/0A++Nb0XfZNXVQ0=;
 b=owEBbQKS/ZANAwAIAW87mNQvxsnYAcsmYgBnFl14aAbfvjyean9OX/0IBGVcmOBWNnuHcCtyg
 31/aaoIkcKJAjMEAAEIAB0WIQQolnD5HDY18KF0JEVvO5jUL8bJ2AUCZxZdeAAKCRBvO5jUL8bJ
 2IMYEACm3r3q3gqs1RP2TQcq3S4pgdxgYPd5tH0Y6o1ZrDy4rPqEXLhB0mlbCxGamVgZQPYG7DB
 putaxZBiGJxHaZBppQrguFkBWj5R3SjLUtBe/MfRzFepFtL79VLEZcjrcPJlngkRU9lWl9/oanZ
 8c/DvnkQRET1xE+EaapJXXfoecczAjkwebQ4pZ3YOyokWXMzkwjrkwGP5+86yLlkQqaC0fKfwhb
 7l+qpTaoR5MlSIZdKMoQNAvwPFWBEEbdLDdHWV3DV/OwMqkP0vIM4x30uPELAEOP0acVVIT0Cfj
 uSWKz1fu3m7bKEHsYZxANf+gkLiG4t5+x6wsOgoBAY/7kCFfN1zKjrKAs/VBsTMXX7tldKo0gSp
 7eBGarHOz2LWynuk9+HdKqmqVydD2h3uALxow1Tc/jlGks7w5ko/BgTvIjKa6WAPSEDxIsu36E8
 z0gSvqZh99Hrt2MmLKVAMKZSkFrz27z9PYlGOA+9KSRvdKv3V2jS5flm8TDRQajMNJ0ULb9ZhEp
 lx4uZH/byQBEXVXg4CWuMqRiJO/j4hYGopTeLkUFuw+gXpW4EZQkASJMwhzMEmR6grYyGR70hyQ
 DYJKzGHeGM9yYSHUEBKAr8rI+Rp1E8tYnB+IsjDLX8jsbDE8N5hjPPLeo4XnEGTa5Jm+QhNOFcF
 OI7XcRZKDEMdeAw==
X-Developer-Key: i=rsworktech@outlook.com; a=openpgp;
 fpr=17AADD6726DDC58B8EE5881757670CCFA42CCF0A
X-Endpoint-Received: by B4 Relay for rsworktech@outlook.com/default with auth_id=219
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The original link returns 404 now. This commit replaces the dead google
site link with archive.org link.

Signed-off-by: Levi Zim <rsworktech@outlook.com>
---
The original link returns 404 now. This commit replaces the dead google
site link with archive.org link.
---
 Documentation/networking/packet_mmap.rst | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/Documentation/networking/packet_mmap.rst b/Documentation/networking/packet_mmap.rst
index dca15d15feaf99ce44d2a73d857928c3eac56da0..02370786e77bc1219f75478cee07264ea12627b5 100644
--- a/Documentation/networking/packet_mmap.rst
+++ b/Documentation/networking/packet_mmap.rst
@@ -16,7 +16,7 @@ ii) transmit network traffic, or any other that needs raw
 
 Howto can be found at:
 
-    https://sites.google.com/site/packetmmap/
+    https://web.archive.org/web/20220404160947/https://sites.google.com/site/packetmmap/
 
 Please send your comments to
     - Ulisses Alonso Camaró <uaca@i.hate.spam.alumni.uv.es>
@@ -166,7 +166,8 @@ As capture, each frame contains two parts::
     /* bind socket to eth0 */
     bind(this->socket, (struct sockaddr *)&my_addr, sizeof(struct sockaddr_ll));
 
- A complete tutorial is available at: https://sites.google.com/site/packetmmap/
+ A complete tutorial is available at:
+ https://web.archive.org/web/20220404160947/https://sites.google.com/site/packetmmap/
 
 By default, the user should put data at::
 

---
base-commit: d95d9a31aceb2021084bc9b94647bc5b175e05e7
change-id: 20241021-packet_mmap_fix_link-e04dc7e7830e

Best regards,
-- 
Levi Zim <rsworktech@outlook.com>

