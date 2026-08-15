From: Bryam Vargas <hexlabsecurity@proton.me>
Subject: [PATCH net 0/2] net/iucv: give afiucv_hs_rcv() the preamble a
 packet_type handler needs
Date: Sat, 15 Aug 2026 11:07:25 -0500
Message-Id: <20260815-b4-disp-dc82fde4-v1-0-e83b10b22ce9@proton.me>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQ6CMBAFf4Xs2U2gUoP+ivFQ2ldZDpV0kZAQ/
 t0Kx5lkZiNFFig9qo0yFlH5pALNpSI/uPQGSyhMpja3umss9y0H0YmD70wMaPnqHSyscbhHKtm
 UEWU9lk9KmOl1Sv32I/z8n9G+/wBtVxAUeQAAAA==
X-Change-ID: 20260815-b4-disp-dc82fde4-3cae5e52ae9f
To: Thorsten Winkler <twinkler@linux.ibm.com>, 
 Jakub Kicinski <kuba@kernel.org>, Eric Dumazet <edumazet@google.com>, 
 Paolo Abeni <pabeni@redhat.com>, "David S. Miller" <davem@davemloft.net>, 
 Alexandra Winter <wintera@linux.ibm.com>
Cc: netdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Ursula Braun <ursula.braun@de.ibm.com>, Simon Horman <horms@kernel.org>, 
 Hidayath Khan <hidayath@linux.ibm.com>, linux-s390@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1786810045; l=1944;
 i=hexlabsecurity@proton.me; s=default; h=from:subject:message-id;
 bh=qZ0dW4sEjY6P00/iB3q5ocylvUh8bfT8JtKM9xlASfA=;
 b=qIwsnmZSn/zMILGaHfwh51RG3zZfPtha1r5PSugqAjXSY2MgcLBrg8FH+jzrjJV9vmzPb5wdC
 1h0Revd4GMoBBHEqp4eU4mWiD+Csv6P3Kr7or+e3bJnBnq9NbNty0Nr
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=xw1AhCtQdvuoQc+bOQIYy9o8G++cp4/VniI2G/tc3G8=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/default with auth_id=893
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

iucv_packet_type is registered with no .dev and no .af_packet_net, so
afiucv_hs_rcv() sits in the machine-global ptype_base[] and sees every frame of
its ethertype from every namespace, on any device. It then trusts the frame: no
namespace test, and no private or writable reference before it rewrites the
payload in place.

  1/2 drop frames from other namespaces -- the only one that crosses a
      privilege boundary, and the only one tagged for stable
  2/2 unshare and cow the head before the in-place rewrite

The two siblings differ in how far they go, so I will not claim more than they
do: net/x25/x25_dev.c does the namespace test and then takes a full skb_copy()
of every frame, and net/ieee802154/socket.c does the namespace test but does not
unshare at all. 2/2 takes the cheaper of the two -- skb_share_check() plus
skb_cow_head() -- which costs a refcount test and a compare when the frame is
already private, and copies only when it is not.

2/2 also covers the headroom that afiucv_swap_src_dest() pushes without
checking. That started as a third patch; it collapsed into this one once it was
clear skb_cow_head() is needed for writability anyway and asking it for ETH_HLEN
rather than nothing is free.

2/2 was surfaced by the sashiko.dev review bot on the thread of a previous af_iucv
patch, which flagged both the missing unshare and the unchecked push; the Closes:
trailer on that patch points at its report.

By inspection; not reproduced. Compile-tested for s390x.

---
Bryam Vargas (2):
      net/iucv: drop HiperSockets frames from other network namespaces
      net/iucv: take a private, writable frame before rewriting it in place

 net/iucv/af_iucv.c | 14 ++++++++++++++
 1 file changed, 14 insertions(+)
---
base-commit: a59f57e2aa127c5354168d2ec4bac920df1be4f4
change-id: 20260815-b4-disp-dc82fde4-3cae5e52ae9f

Best regards,
--  
Bryam Vargas <hexlabsecurity@proton.me>

