From: Ben Kuo <ben.kuo.tw@proton.me>
Date: Thu, 15 Oct 2026 21:48:33 +0800
Subject: [PATCH] man/man7/epoll.7: Note that an edge-triggered listener
 needs an accept loop
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-epoll-et-listener-v1-1-2cc0027b658c@proton.me>
X-B4-Tracking: v=1; b=H4sIALDZ0GoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDA0NT3dSC/Jwc3dQS3ZzM4pLUvNQi3WRLC3Pj5ORUM6OkZCWgvoKi1LT
 MCrCZ0bG1tQA35FmYYwAAAA==
X-Change-ID: 20261015-epoll-et-listener-c9873cce62bc
To: Alejandro Colomar <alx@kernel.org>
Cc: linux-man@vger.kernel.org, Ben Kuo <ben.kuo.tw@proton.me>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792072148; l=1792;
 i=ben.kuo.tw@proton.me; s=20261015; h=from:subject:message-id;
 bh=LJVki2WUPiCCjNBGmHpgB0vFA15C1Cs0d02BFrGChUw=;
 b=e+Hh17gIpIWqdM1/7kWgO+Ee0CqWlG3r/u9CQJDW8VLdyfg/DXs+gNi9/KwG3U0pO5sCJ03GJ
 2VA8smHdI0fD1VC0bjiX/CHihxuQVyBzjrP0CgM8c9gUY6jfEghUz1O
X-Developer-Key: i=ben.kuo.tw@proton.me; a=ed25519;
 pk=VCZ2SPSJe/Vhd2Lwi18Oi3ovxGkT+76oncbTcgGW5wI=
X-Endpoint-Received: by B4 Relay for ben.kuo.tw@proton.me/20261015 with auth_id=1192
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The example registers the listening socket as level-triggered and
calls accept(2) once per event, but doesn't say that this only works
for a level-triggered listener.  If a reader adds EPOLLET to the
listening socket in the example, connections are left in the accept
queue and the server stalls.

Tested on Linux 6.12 (Debian 13, arm64) with an echo server whose
listening socket is registered with EPOLLET, and a client that opens
2000 connections at once.  With one accept4(2) call per listener
event, the client never finishes: ss(8) shows 1420 connections left
in the accept queue (Recv-Q), while the server stays blocked in
epoll_wait(2).  With accept4(2) called in a loop until EAGAIN, all
connections are echoed.

Link: <https://github.com/benkuotw/epoll-lab>
Signed-off-by: Ben Kuo <ben.kuo.tw@proton.me>
---
 man/man7/epoll.7 | 10 ++++++++++
 1 file changed, 10 insertions(+)

diff --git a/man/man7/epoll.7 b/man/man7/epoll.7
index 2628cbb168b499786e495cf3c614fc5e58217295..aff844a568a5cd6d8eb310ed833266a0ccfd0a4d 100644
--- a/man/man7/epoll.7
+++ b/man/man7/epoll.7
@@ -339,6 +339,16 @@ for (;;) {
 .EE
 .in
 .P
+The listening socket in this example is level-triggered.
+If it is registered with
+.BR EPOLLET ,
+.BR accept (2)
+must be called in a loop until it fails with
+.BR EAGAIN :
+a single event may report several pending connections,
+and no further event is reported for those still queued
+until another connection arrives.
+.P
 When used as an edge-triggered interface, for performance reasons, it is
 possible to add the file descriptor inside the
 .B epoll

---
base-commit: c6cefe27dd02beaf518bb654493e5f09e62b3225
change-id: 20261015-epoll-et-listener-c9873cce62bc

Best regards,
-- 
Ben Kuo <ben.kuo.tw@proton.me>

