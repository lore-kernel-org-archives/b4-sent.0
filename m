From: Joel Granados <joel.granados@kernel.org>
Date: Thu, 26 Nov 2026 12:47:46 +0100
Subject: [PATCH RFC 6/9] ipv4: Register ipv4_net_table as a template
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261126-lklm-sysctl-ctx-flatarray-v1-6-d7fc9cc9b03e@kernel.org>
References: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
In-Reply-To: <20261126-lklm-sysctl-ctx-flatarray-v1-0-d7fc9cc9b03e@kernel.org>
To: Kees Cook <kees@kernel.org>, Alexey Gladkov <legion@kernel.org>, 
 David Laight <david.laight.linux@gmail.com>, Wen Yang <wen.yang@linux.dev>
Cc: Eric Dumazet <edumazet@kernel.org>, Jakub Kicinski <kuba@kernel.org>, 
 Paolo Abeni <pabeni@redhat.com>, Simon Horman <horms@kernel.org>, 
 Linus Torvalds <torvalds@linux-foundation.org>, 
 linux-kernel@vger.kernel.org, linux-fsdevel@vger.kernel.org, 
 netdev@vger.kernel.org, Joel Granados <joel.granados@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=40497;
 i=joel.granados@kernel.org; h=from:subject:message-id;
 bh=oSMtkkRJb6haZ71YK3M5fia6zugX0TM6idwAumSh7z4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGsIHGUEmvNmnmsX2d1PPhnYIL3ToXfM7tIIH
 R8gke83HH/BiIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJrCBxlAAoJELqXzVK3
 lkFPnc4L/2dC406ccLBNJ2d3jVOruCr3stJZf581DgbzMonoq+cptfqjsne/dXKOubx+ALwBPLD
 dwse+urCZEJ786hUzn5d+8Xo9hDJrNDRoPndvEZUAI4q3TEt4nSHBUQPcXxKq4jkWGKqx76qmcq
 xtSLOGYuEFmhQJvWxNC5GAFLNVTqJxRSQpwYKRQskx8x/8mlDYpp6cJ3qPxFLnjXUJU25/0jfmE
 EF52cVPXheYCjC+WbLBxfM4CMUij9tlxqPVfTj1FYgg6TZ++NIFGLAFZPivOd3XrtCpilfUG3MR
 5rExHaOjZ9E+Vk/lrh1pyEWMMaVxIteY916NhMsK7BGg1L2QdSD559ld3pZVLEuwKl+MhWP8LWT
 DssEUb2as29reIu7h10uHxMM9Uo7LQLOTqdhjDVq26kghL6XHPucZKZefbGPQxBiHjBfLznhO0P
 FPWw9WwM8YNPNNDr5rGiQStvMeZgt86f1AbCkLPkOSzyZfoxCD53twdLXFZOghXdbeh82BYIZ26
 N0=
X-Developer-Key: i=joel.granados@kernel.org; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for joel.granados@kernel.org/default with auth_id=239
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Flag the members of ipv4_net_table that differ per namespace and
register it through register_net_sysctl_tmpl():

  * SYSCTL_OVERLAY_DATA on the 127 entries with a .data pointer,
  * SYSCTL_OVERLAY_EXTRA2 on tcp_reordering, whose bound is the
    namespace's tcp_max_reordering,
  * SYSCTL_OVERLAY_MODE on tcp_allowed_congestion_control,
  * dataless entry that becomes read-only outside init_net

Rename ipv4_net_table_dup() to ipv4_net_table_overlay(), build the
overlay for init_net as well, free it once the call returns and stop
freeing ctl_table_arg in ipv4_sysctl_exit_net().

A namespace then keeps the context arrays in its header instead of a
copy of the whole table. init_net needs an overlay too because the core
refuses a flagged entry that has no context value.

Signed-off-by: Joel Granados <joel.granados@kernel.org>
---
 net/ipv4/sysctl_net_ipv4.c | 163 +++++++++++++++++++++++++++++++++++++++------
 1 file changed, 143 insertions(+), 20 deletions(-)

diff --git a/net/ipv4/sysctl_net_ipv4.c b/net/ipv4/sysctl_net_ipv4.c
index bf193e7ec51684a78387d30c959b5ad235c6865d..876bbec562e539520f0642e9567cd498a3678f8d 100644
--- a/net/ipv4/sysctl_net_ipv4.c
+++ b/net/ipv4/sysctl_net_ipv4.c
@@ -633,6 +633,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.tcp_death_row.sysctl_max_tw_buckets,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec
 	},
 	{
@@ -640,6 +641,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_icmp_echo_ignore_all,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE
@@ -649,6 +651,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_icmp_echo_enable_probe,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE
@@ -658,6 +661,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_icmp_echo_ignore_broadcasts,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE
@@ -667,6 +671,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_icmp_ignore_bogus_error_responses,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE
@@ -676,6 +681,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_icmp_errors_use_inbound_ifaddr,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE
@@ -685,6 +691,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_icmp_errors_extension_mask,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= &icmp_errors_extension_mask_all,
@@ -694,6 +701,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_icmp_ratelimit,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_ms_jiffies,
 	},
 	{
@@ -701,6 +709,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_icmp_ratemask,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec
 	},
 	{
@@ -708,6 +717,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_icmp_msgs_per_sec,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 	},
@@ -716,6 +726,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_icmp_msgs_burst,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 	},
@@ -724,6 +735,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.ping_group_range.range,
 		.maxlen		= sizeof(gid_t)*2,
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= ipv4_ping_group_range,
 	},
 #ifdef CONFIG_NET_L3_MASTER_DEV
@@ -732,6 +744,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_raw_l3mdev_accept,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
@@ -742,6 +755,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_ecn,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= &tcp_ecn_mode_max,
@@ -751,6 +765,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_ecn_option,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_THREE,
@@ -760,6 +775,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_ecn_option_beacon,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_THREE,
@@ -769,6 +785,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_ecn_fallback,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
@@ -778,6 +795,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_ip_dynaddr,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -785,6 +803,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_ip_early_demux,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -792,6 +811,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data           = &init_net.ipv4.sysctl_udp_early_demux,
 		.maxlen         = sizeof(u8),
 		.mode           = 0644,
+		.flags          = SYSCTL_OVERLAY_DATA,
 		.proc_handler   = proc_dou8vec_minmax,
 	},
 	{
@@ -799,6 +819,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data           = &init_net.ipv4.sysctl_tcp_early_demux,
 		.maxlen         = sizeof(u8),
 		.mode           = 0644,
+		.flags          = SYSCTL_OVERLAY_DATA,
 		.proc_handler   = proc_dou8vec_minmax,
 	},
 	{
@@ -806,6 +827,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data           = &init_net.ipv4.sysctl_nexthop_compat_mode,
 		.maxlen         = sizeof(u8),
 		.mode           = 0644,
+		.flags          = SYSCTL_OVERLAY_DATA,
 		.proc_handler   = proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
@@ -815,6 +837,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_ip_default_ttl,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= &ip_ttl_min,
 		.extra2		= &ip_ttl_max,
@@ -824,6 +847,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.maxlen		= 0,
 		.data		= &init_net,
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= ipv4_local_port_range,
 	},
 	{
@@ -831,6 +855,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.maxlen		= sizeof(u32),
 		.data		= &init_net.ipv4.sysctl_ip_local_port_step_width,
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_douintvec,
 	},
 	{
@@ -838,6 +863,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_local_reserved_ports,
 		.maxlen		= 65536,
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_do_large_bitmap,
 	},
 	{
@@ -845,6 +871,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_ip_no_pmtu_disc,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -852,6 +879,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_ip_fwd_use_pmtu,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -859,6 +887,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_ip_fwd_update_priority,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler   = ipv4_fwd_update_priority,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
@@ -868,6 +897,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_ip_nonlocal_bind,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -875,6 +905,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_ip_autobind_reuse,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1         = SYSCTL_ZERO,
 		.extra2         = SYSCTL_ONE,
@@ -884,6 +915,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_fwmark_reflect,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -891,6 +923,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_fwmark_accept,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 #ifdef CONFIG_NET_L3_MASTER_DEV
@@ -899,6 +932,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_l3mdev_accept,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
@@ -909,6 +943,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_mtu_probing,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -916,6 +951,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_base_mss,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec,
 	},
 	{
@@ -923,6 +959,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_min_snd_mss,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= &tcp_min_snd_mss_min,
 		.extra2		= &tcp_min_snd_mss_max,
@@ -932,6 +969,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_mtu_probe_floor,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= &tcp_min_snd_mss_min,
 		.extra2		= &tcp_min_snd_mss_max,
@@ -941,6 +979,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_probe_threshold,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec,
 	},
 	{
@@ -948,6 +987,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_probe_interval,
 		.maxlen		= sizeof(u32),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_douintvec_minmax,
 		.extra2		= &u32_max_div_HZ,
 	},
@@ -956,6 +996,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_igmp_llm_reports,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -963,6 +1004,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_igmp_max_memberships,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec
 	},
 	{
@@ -970,6 +1012,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_igmp_max_msf,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec
 	},
 #ifdef CONFIG_IP_MULTICAST
@@ -978,6 +1021,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_igmp_qrv,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ONE
 	},
@@ -986,6 +1030,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.procname	= "tcp_congestion_control",
 		.data		= &init_net.ipv4.tcp_congestion_control,
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.maxlen		= TCP_CA_NAME_MAX,
 		.proc_handler	= proc_tcp_congestion_control,
 	},
@@ -999,6 +1044,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.procname	= "tcp_allowed_congestion_control",
 		.maxlen		= TCP_CA_BUF_MAX,
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_MODE,
 		.proc_handler   = proc_allowed_congestion_control,
 	},
 	{
@@ -1006,6 +1052,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_keepalive_time,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_jiffies,
 	},
 	{
@@ -1013,6 +1060,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_keepalive_probes,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1020,6 +1068,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_keepalive_intvl,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_jiffies,
 	},
 	{
@@ -1027,6 +1076,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_syn_retries,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= &tcp_syn_retries_min,
 		.extra2		= &tcp_syn_retries_max
@@ -1036,6 +1086,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_synack_retries,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 #ifdef CONFIG_SYN_COOKIES
@@ -1044,6 +1095,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_syncookies,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 #endif
@@ -1052,6 +1104,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_migrate_req,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE
@@ -1061,6 +1114,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_reordering,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA | SYSCTL_OVERLAY_EXTRA2,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ONE,
 		.extra2		= &init_net.ipv4.sysctl_tcp_max_reordering,
@@ -1070,6 +1124,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_retries1,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra2		= &tcp_retr1_max
 	},
@@ -1078,6 +1133,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_retries2,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1085,6 +1141,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_orphan_retries,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1092,6 +1149,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_fin_timeout,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_jiffies,
 	},
 	{
@@ -1099,6 +1157,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_notsent_lowat,
 		.maxlen		= sizeof(unsigned int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_douintvec,
 	},
 	{
@@ -1106,6 +1165,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_tw_reuse,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_TWO,
@@ -1115,6 +1175,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_tw_reuse_delay,
 		.maxlen		= sizeof(unsigned int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_douintvec_minmax,
 		.extra1		= SYSCTL_ONE,
 		.extra2		= &tcp_tw_reuse_delay_max,
@@ -1124,6 +1185,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_max_syn_backlog,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec
 	},
 	{
@@ -1131,11 +1193,13 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_fastopen,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec,
 	},
 	{
 		.procname	= "tcp_fastopen_key",
 		.mode		= 0600,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.data		= &init_net.ipv4.sysctl_tcp_fastopen,
 		/* maxlen to print the list of keys in hex (*2), with dashes
 		 * separating doublewords and a comma in between keys.
@@ -1150,6 +1214,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_fastopen_blackhole_timeout,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_tfo_blackhole_detect_timeout,
 		.extra1		= SYSCTL_ZERO,
 	},
@@ -1159,6 +1224,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_fib_multipath_use_neigh,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
@@ -1168,6 +1234,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_fib_multipath_hash_policy,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_fib_multipath_hash_policy,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_THREE,
@@ -1177,6 +1244,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_fib_multipath_hash_fields,
 		.maxlen		= sizeof(u32),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_fib_multipath_hash_fields,
 		.extra1		= SYSCTL_ONE,
 		.extra2		= &fib_multipath_hash_fields_all_mask,
@@ -1186,6 +1254,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net,
 		.maxlen		= sizeof(u32),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_fib_multipath_hash_seed,
 	},
 #endif
@@ -1194,6 +1263,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.maxlen		= sizeof(int),
 		.data		= &init_net.ipv4.sysctl_ip_prot_sock,
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= ipv4_privileged_ports,
 	},
 #ifdef CONFIG_NET_L3_MASTER_DEV
@@ -1202,6 +1272,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_udp_l3mdev_accept,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
@@ -1212,6 +1283,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_sack,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1219,6 +1291,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_window_scaling,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1226,6 +1299,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_timestamps,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1233,6 +1307,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_early_retrans,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_FOUR,
@@ -1242,6 +1317,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_recovery,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1249,6 +1325,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data           = &init_net.ipv4.sysctl_tcp_thin_linear_timeouts,
 		.maxlen         = sizeof(u8),
 		.mode           = 0644,
+		.flags          = SYSCTL_OVERLAY_DATA,
 		.proc_handler   = proc_dou8vec_minmax,
 	},
 	{
@@ -1256,6 +1333,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_slow_start_after_idle,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1263,6 +1341,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_retrans_collapse,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1270,6 +1349,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_stdurg,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1277,6 +1357,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_rfc1337,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1284,6 +1365,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_abort_on_overflow,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1291,6 +1373,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_fack,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1298,6 +1381,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_max_reordering,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ONE,
 	},
@@ -1306,6 +1390,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_dsack,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1313,6 +1398,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_app_win,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= &tcp_app_win_max,
@@ -1322,6 +1408,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_adv_win_scale,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= &tcp_adv_win_scale_min,
 		.extra2		= &tcp_adv_win_scale_max,
@@ -1331,6 +1418,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_frto,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1338,6 +1426,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_nometrics_save,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1345,6 +1434,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_no_ssthresh_metrics_save,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
@@ -1354,6 +1444,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_moderate_rcvbuf,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1361,6 +1452,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_rcvbuf_low_rtt,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_INT_MAX,
@@ -1370,6 +1462,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_tso_win_divisor,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1377,6 +1470,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_workaround_signed_windows,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 	},
 	{
@@ -1384,6 +1478,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_limit_output_bytes,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec
 	},
 	{
@@ -1391,6 +1486,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_challenge_ack_limit,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec
 	},
 	{
@@ -1398,6 +1494,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_min_tso_segs,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ONE,
 	},
@@ -1406,6 +1503,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_tso_rtt_log,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra2		= &tcp_tso_rtt_log_max,
 	},
@@ -1414,6 +1512,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_min_rtt_wlen,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= &one_day_secs
@@ -1423,6 +1522,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_autocorking,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
@@ -1432,6 +1532,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_invalid_ratelimit,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_ms_jiffies,
 	},
 	{
@@ -1439,6 +1540,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_pacing_ss_ratio,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE_THOUSAND,
@@ -1448,6 +1550,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_pacing_ca_ratio,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE_THOUSAND,
@@ -1457,6 +1560,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_wmem,
 		.maxlen		= sizeof(init_net.ipv4.sysctl_tcp_wmem),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ONE,
 	},
@@ -1465,6 +1569,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_rmem,
 		.maxlen		= sizeof(init_net.ipv4.sysctl_tcp_rmem),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= &tcp_min_rcvbuf,
 	},
@@ -1473,6 +1578,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_comp_sack_delay_ns,
 		.maxlen		= sizeof(unsigned long),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_doulongvec_minmax,
 	},
 	{
@@ -1480,6 +1586,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_comp_sack_rtt_percent,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ONE,
 		.extra2		= SYSCTL_ONE_THOUSAND,
@@ -1489,6 +1596,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_comp_sack_slack_ns,
 		.maxlen		= sizeof(unsigned long),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_doulongvec_minmax,
 	},
 	{
@@ -1496,6 +1604,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_comp_sack_nr,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 	},
@@ -1504,6 +1613,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_backlog_ack_defer,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
@@ -1513,6 +1623,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data           = &init_net.ipv4.sysctl_tcp_reflect_tos,
 		.maxlen         = sizeof(u8),
 		.mode           = 0644,
+		.flags          = SYSCTL_OVERLAY_DATA,
 		.proc_handler   = proc_dou8vec_minmax,
 		.extra1         = SYSCTL_ZERO,
 		.extra2         = SYSCTL_ONE,
@@ -1521,6 +1632,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.procname	= "tcp_ehash_entries",
 		.data		= &init_net.ipv4.sysctl_tcp_child_ehash_entries,
 		.mode		= 0444,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_tcp_ehash_entries,
 	},
 	{
@@ -1528,6 +1640,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_child_ehash_entries,
 		.maxlen		= sizeof(unsigned int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_douintvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= &tcp_child_ehash_entries_max,
@@ -1536,6 +1649,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.procname	= "udp_hash_entries",
 		.data		= &init_net.ipv4.sysctl_udp_child_hash_entries,
 		.mode		= 0444,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_udp_hash_entries,
 	},
 	{
@@ -1543,6 +1657,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_udp_child_hash_entries,
 		.maxlen		= sizeof(unsigned int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_douintvec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= &udp_child_hash_entries_max,
@@ -1552,6 +1667,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_udp_rmem_min,
 		.maxlen		= sizeof(init_net.ipv4.sysctl_udp_rmem_min),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ONE
 	},
@@ -1560,6 +1676,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_udp_wmem_min,
 		.maxlen		= sizeof(init_net.ipv4.sysctl_udp_wmem_min),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ONE
 	},
@@ -1568,6 +1685,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_fib_notify_on_flag_change,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_TWO,
@@ -1577,6 +1695,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data           = &init_net.ipv4.sysctl_tcp_plb_enabled,
 		.maxlen         = sizeof(u8),
 		.mode           = 0644,
+		.flags          = SYSCTL_OVERLAY_DATA,
 		.proc_handler   = proc_dou8vec_minmax,
 		.extra1         = SYSCTL_ZERO,
 		.extra2         = SYSCTL_ONE,
@@ -1586,6 +1705,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data           = &init_net.ipv4.sysctl_tcp_plb_idle_rehash_rounds,
 		.maxlen         = sizeof(u8),
 		.mode           = 0644,
+		.flags          = SYSCTL_OVERLAY_DATA,
 		.proc_handler   = proc_dou8vec_minmax,
 		.extra2		= &tcp_plb_max_rounds,
 	},
@@ -1594,6 +1714,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data           = &init_net.ipv4.sysctl_tcp_plb_rehash_rounds,
 		.maxlen         = sizeof(u8),
 		.mode           = 0644,
+		.flags          = SYSCTL_OVERLAY_DATA,
 		.proc_handler   = proc_dou8vec_minmax,
 		.extra2         = &tcp_plb_max_rounds,
 	},
@@ -1602,6 +1723,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data           = &init_net.ipv4.sysctl_tcp_plb_suspend_rto_sec,
 		.maxlen         = sizeof(u8),
 		.mode           = 0644,
+		.flags          = SYSCTL_OVERLAY_DATA,
 		.proc_handler   = proc_dou8vec_minmax,
 	},
 	{
@@ -1609,6 +1731,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data           = &init_net.ipv4.sysctl_tcp_plb_cong_thresh,
 		.maxlen         = sizeof(int),
 		.mode           = 0644,
+		.flags          = SYSCTL_OVERLAY_DATA,
 		.proc_handler   = proc_dointvec_minmax,
 		.extra1         = SYSCTL_ZERO,
 		.extra2         = &tcp_plb_max_cong_thresh,
@@ -1618,6 +1741,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_syn_linear_timeouts,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= &tcp_syn_linear_timeouts_max,
@@ -1627,6 +1751,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_shrink_window,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
@@ -1636,6 +1761,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_pingpong_thresh,
 		.maxlen		= sizeof(u8),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dou8vec_minmax,
 		.extra1		= SYSCTL_ONE,
 	},
@@ -1644,6 +1770,7 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_rto_min_us,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ONE,
 	},
@@ -1652,13 +1779,19 @@ static const struct ctl_table ipv4_net_table[] = {
 		.data		= &init_net.ipv4.sysctl_tcp_rto_max_ms,
 		.maxlen		= sizeof(int),
 		.mode		= 0644,
+		.flags		= SYSCTL_OVERLAY_DATA,
 		.proc_handler	= proc_dointvec_minmax,
 		.extra1		= SYSCTL_ONE_THOUSAND,
 		.extra2		= &tcp_rto_max_max,
 	},
 };
 
-static const struct ctl_table *ipv4_net_table_dup(struct net *net)
+/*
+ * Fill in, for @net, the members of ipv4_net_table that are flagged
+ * SYSCTL_OVERLAY_*. The copy only lives for the registration call; the
+ * table itself is shared by every namespace.
+ */
+static struct ctl_table *ipv4_net_table_overlay(struct net *net)
 {
 	size_t table_size = ARRAY_SIZE(ipv4_net_table);
 	struct ctl_table *table;
@@ -1674,7 +1807,7 @@ static const struct ctl_table *ipv4_net_table_dup(struct net *net)
 			 * the current struct net
 			 */
 			table[i].data += (void *)net - (void *)&init_net;
-		} else {
+		} else if (!net_eq(net, &init_net)) {
 			/* Entries without data pointer are global;
 			 * Make them read-only in non-init_net ns
 			 */
@@ -1689,20 +1822,17 @@ static const struct ctl_table *ipv4_net_table_dup(struct net *net)
 
 static __net_init int ipv4_sysctl_init_net(struct net *net)
 {
-	size_t table_size = ARRAY_SIZE(ipv4_net_table);
-	const struct ctl_table *table;
+	struct ctl_table *table;
 
-	table = ipv4_net_table;
-	if (!net_eq(net, &init_net)) {
-		table = ipv4_net_table_dup(net);
-		if (!table)
-			goto err_alloc;
-	}
+	table = ipv4_net_table_overlay(net);
+	if (!table)
+		goto err_alloc;
 
-	net->ipv4.ipv4_hdr = register_net_sysctl_sz(net, "net/ipv4", table,
-						    table_size);
+	net->ipv4.ipv4_hdr = register_net_sysctl_tmpl(net, "net/ipv4",
+						      ipv4_net_table, table);
+	kfree(table);
 	if (!net->ipv4.ipv4_hdr)
-		goto err_reg;
+		goto err_alloc;
 
 	net->ipv4.sysctl_local_reserved_ports = kzalloc(65536 / 8, GFP_KERNEL);
 	if (!net->ipv4.sysctl_local_reserved_ports)
@@ -1714,20 +1844,13 @@ static __net_init int ipv4_sysctl_init_net(struct net *net)
 
 err_ports:
 	unregister_net_sysctl_table(net->ipv4.ipv4_hdr);
-err_reg:
-	if (!net_eq(net, &init_net))
-		kfree(table);
 err_alloc:
 	return -ENOMEM;
 }
 
 static __net_exit void ipv4_sysctl_exit_net(struct net *net)
 {
-	const struct ctl_table *table;
-
-	table = net->ipv4.ipv4_hdr->ctl_table_arg;
 	unregister_net_sysctl_table(net->ipv4.ipv4_hdr);
-	kfree(table);
 	kfree(net->ipv4.sysctl_local_reserved_ports);
 }
 

-- 
2.50.1

