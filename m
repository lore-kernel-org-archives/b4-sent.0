From: Andy Pan <i@andypan.me>
Date: Sat, 27 Jul 2024 14:52:17 +0000
Subject: [PATCH v2] epoll.7: clarify the event distribution under
 edge-triggered mode
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240727-epoll-et-desc-v2-1-c99b2ac66775@andypan.me>
X-B4-Tracking: v=1; b=H4sIAKAJpWYC/3XMQQ6CMBCF4auQWTumFLTWlfcwLFqYyiTYNi0hE
 sLdrexd/i953waZElOGe7VBooUzB19CniroR+NfhDyUBilkK5RUSDFME9KMA+UeRUtGm4sWrrF
 QPjGR48/hPbvSI+c5pPXgl/q3/pOWGmtstLDG9Vd1s/ph/LBG489vgm7f9y9TuJ/6qwAAAA==
To: Alejandro Colomar <alx@kernel.org>
Cc: linux-man@vger.kernel.org, linux-api@vger.kernel.org, 
 Andy Pan <i@andypan.me>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722091946; l=3291;
 i=i@andypan.me; s=20240727; h=from:subject:message-id;
 bh=FEZtoMXszoRwev9xfXPnAge3Rf7kCy6kqW7B5PqXjns=;
 b=j/Y685MHW8wIn/bEqw0mx5x4u1yHIXnKRMFKoHIe6dDSxxjNI9fpwJPaS2K1dIjo0tLAHtOKZ
 W7jUhB6Qlq0Cg/IzFhVenUAUXj6gvP6UiA5/RP8QinPZavJafjPyTIr
X-Developer-Key: i=i@andypan.me; a=ed25519;
 pk=ZLGY5dzAGPy8bpSKbl9Jfyp/Ud0eac0BY5cKedQXMcw=
X-Endpoint-Received: by B4 Relay for i@andypan.me/20240727 with auth_id=190
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

For the moment, the edge-triggered epoll generates an event for each
receipt of a chunk of data, that is to say, epoll_wait() will return
and tell us a monitored file descriptor is ready whenever there is a
new activity on that FD since we were last informed about that FD.
This is not a real _edge_ implementation for epoll, but it's been
working this way for years and plenty of projects are relying on it.

There are several renowned open-source projects relying on this feature
for notification function (with eventfd), such as nginx [1], netty [2],
tokio [3], libevent [4], ect. [5] These projects are widely used in today's
Internet infrastructures. Thus, changing this behavior of epoll ET will
fundamentally break them and cause a significant negative impact.
Linux has changed it for pipe before [6], breaking some Android libraries,
which had got "reverted" somehow. [7] [8]

Nevertheless, the paragraph in the manual pages describing this
characteristic of epoll ET seems ambiguous, I think a more explict
sentence should be used to clarify it. We're improving the notification
mechanism for libuv recently by exploiting this feature with eventfd,
which brings us a significant performance boost. [9]

Therefore, we (as well as the maintainers of nginx, netty, tokio, etc.)
would have a sense of security to build an enhanced notification function
based on this feature if there is a guarantee of retaining this implementation
of epoll ET for the backward compatibility in the man pages.

[1]: https://github.com/nginx/nginx/blob/efc6a217b92985a1ee211b6bb7337cd2f62deb90/src/event/modules/ngx_epoll_module.c#L386-L457
[2]: https://github.com/netty/netty/pull/9192
[3]: https://github.com/tokio-rs/mio/blob/309daae21ecb1d46203a7dbc0cf4c80310240cba/src/sys/unix/waker.rs#L111-L143
[4]: https://github.com/libevent/libevent/blob/525f5d0a14c9c103be750f2ca175328c25505ea4/event.c#L2597-L2614
[5]: https://github.com/libuv/libuv/pull/4400#issuecomment-2123798748
[6]: https://lkml.iu.edu/hypermail/linux/kernel/2010.1/04363.html
[7]: https://github.com/torvalds/linux/commit/3a34b13a88caeb2800ab44a4918f230041b37dd9
[8]: https://github.com/torvalds/linux/commit/3b844826b6c6affa80755254da322b017358a2f4
[9]: https://github.com/libuv/libuv/pull/4400#issuecomment-2103232402

Signed-off-by: Andy Pan <i@andypan.me>
---
I've added it to the commit description, please take a look again, thanks!
---
Changes in v2:
- [PATCH v2] epoll.7: add git commit description
- Link to v1: https://lore.kernel.org/r/20240727-epoll-et-desc-v1-1-390bafc678b9@andypan.me
---
 man/man7/epoll.7 | 1 +
 1 file changed, 1 insertion(+)

diff --git a/man/man7/epoll.7 b/man/man7/epoll.7
index 951500131..361d9db99 100644
--- a/man/man7/epoll.7
+++ b/man/man7/epoll.7
@@ -172,6 +172,7 @@ .SS Level-triggered and edge-triggered
 Since even with edge-triggered
 .BR epoll ,
 multiple events can be generated upon receipt of multiple chunks of data,
+that is, an event will be generated upon each receipt of a chunk of data,
 the caller has the option to specify the
 .B EPOLLONESHOT
 flag, to tell

---
base-commit: cbc0a111e4dceea2037c51098de33e6bc8c16a5c
change-id: 20240727-epoll-et-desc-04ea9a590f3b

Best regards,
-- 
Andy Pan <i@andypan.me>

