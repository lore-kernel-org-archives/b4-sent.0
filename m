From: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
Date: Sun, 22 Nov 2026 10:46:18 -0300
Subject: [PATCH v3 3/3] docs/translations/pt_BR: process: add
 handling-regressions.rst (3/3)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20261122-handling-regressions-v3-3-e3d5ea982948@gmail.com>
References: <20261122-handling-regressions-v3-0-e3d5ea982948@gmail.com>
In-Reply-To: <20261122-handling-regressions-v3-0-e3d5ea982948@gmail.com>
To: linux-doc@vger.kernel.org
Cc: danielmaraboo@gmail.com, corbet@lwn.net, rdunlap@infradead.org, 
 skhan@linuxfoundation.org, Eduardo Pereira Cruz <dreduardocruz@gmail.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795355175; l=29898;
 i=dreduardocruz@gmail.com; s=20261119; h=from:subject:message-id;
 bh=CnU6QXydIIaJR7FD8t+D3YpQeS5GyNA6NNp/03K1Hwo=;
 b=9sCnqSJ1BPaYHCxlbhDEcbXjkYScVYZDjgvS37R2H9MADQwXsni4TSZdeJd4kN1+yZSdaZVul
 yOHILj0+GzUCS6AmHLccFNDWCgRrlSSlopO1w0HsKd3feuTcb5b7qkQ
X-Developer-Key: i=dreduardocruz@gmail.com; a=ed25519;
 pk=2dtL+BL/x70sROmAvlskv9dbjj274zlPkLBVu4gJJiA=
X-Endpoint-Received: by B4 Relay for dreduardocruz@gmail.com/20261119 with auth_id=1571
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Finish the translation with the quotes from Linus Torvalds about the
"no regressions" rule, and hook the new document into the pt_BR process
index.

Signed-off-by: Eduardo Pereira Cruz <dreduardocruz@gmail.com>
---
 .../pt_BR/process/handling-regressions.rst         | 592 +++++++++++++++++++++
 1 file changed, 592 insertions(+)

diff --git a/Documentation/translations/pt_BR/process/handling-regressions.rst b/Documentation/translations/pt_BR/process/handling-regressions.rst
index 8f18bc28689e..c57e5b2091ec 100644
--- a/Documentation/translations/pt_BR/process/handling-regressions.rst
+++ b/Documentation/translations/pt_BR/process/handling-regressions.rst
@@ -547,3 +547,595 @@ e `documentação de referência
 <https://gitlab.com/knurd42/regzbot/-/blob/main/docs/reference.md>`_,
 ambos cobrindo mais detalhes do que a seção acima.
 
+Citações de Linus sobre regressão
+---------------------------------
+
+As declarações a seguir, de Linus Torvalds, oferecem alguma compreensão
+sobre a regra "sem regressões" do Linux e sobre como ele espera que as
+regressões sejam tratadas:
+
+Sobre a rapidez com que as regressões devem ser corrigidas
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-22 <https://lore.kernel.org/all/CAHk-=wheQNiW_WtHGO7bKkT7Uib-p+ai2JP9M+z+FYcZ6CAxYA@mail.gmail.com/>`_::
+
+    Mas um usuário reclamando deve basicamente resultar em uma correção
+    imediata - possivelmente um "reverter e repensar".
+
+  Com um esclarecimento posterior, de `2026-01-28 <https://lore.kernel.org/all/CAHk-%3Dwi86AosXs66-yi54%2BmpQjPu0upxB8ZAfG%2BLsMyJmcuMSA@mail.gmail.com/>`_::
+
+    Vale notar também que "imediata" obviamente não significa "neste
+    *segundo* em que o problema foi relatado".
+
+    Mas se for uma regressão com um commit conhecido que a causou, penso
+    que a regra geral deve ser "dentro de uma semana", de preferência
+    antes do próximo rc.
+
+* De `2023-04-21 <https://lore.kernel.org/all/CAHk-=wgD98pmSK3ZyHk_d9kZ2bhgN6DuNZMAJaV0WTtbkf=RDw@mail.gmail.com/>`_::
+
+    Commits sabidamente quebrados ou
+     (a) recebem uma correção em tempo hábil que não traga outras questões
+    ou
+     (b) são revertidos
+
+* De `2021-09-20(2) <https://lore.kernel.org/all/CAHk-=wgOvmtRw1TNbMC1rn5YqyTKyn0hz+sc4k0DGNn++u9aYw@mail.gmail.com/>`_::
+
+    [...] a revisão não deveria barrar regressões relatadas de código
+    existente. Isso é apenas _teste_ básico - ou a correção deve ser
+    aplicada, ou - se a correção for invasiva ou feia demais - a fonte
+    problemática da regressão deve ser revertida.
+
+    Revisão deveria ser sobre código novo, não deveria barrar "existe um
+    relato de bug, aqui está a correção óbvia".
+* De `2023-05-08 <https://lore.kernel.org/all/CAHk-=wgzU8_dGn0Yg+DyX7ammTkDUCyEJ4C=NvnHRhxKWC7Wpw@mail.gmail.com/>`_::
+
+    Se algo nem sequer compila, deve ser corrigido o quanto antes, sim.
+
+Sobre como corrigir regressões com reversões pode ajudar a evitar o
+esgotamento de mantenedores
+~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-28 <https://lore.kernel.org/all/CAHk-%3Dwi86AosXs66-yi54%2BmpQjPu0upxB8ZAfG%2BLsMyJmcuMSA@mail.gmail.com/>`_::
+
+    > Então como eu/nós podemos fazer "correções imediatas" acontecerem com
+    > mais frequência sem contribuir para o esgotamento de mantenedores?
+
+    [...] o modelo de "reverter e repensar" [...] costuma ser uma boa
+    ideia em geral [...]
+
+    Justamente para que os mantenedores não fiquem estressados por terem um
+    relato de problema pendente sobre o qual as pessoas insistem em cobrar.
+
+    Penso que às vezes as pessoas ficam um pouco apegadas demais às
+    mudanças que fizeram, e reverter é visto como "drástico demais", mas
+    penso que costuma ser a solução rápida e fácil quando não há alguma
+    resposta óbvia a um relato de regressão.
+
+Sobre correções quando o último -rc ou versão está próximo
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-02-01 <https://lore.kernel.org/all/CAHk-%3DwhXTw1oPsa%2BTLuY1Rc9D1OAiPVOdR_-R2xG45kwDObKdA@mail.gmail.com/>`_::
+
+    Então penso que prefiro vê-las entrar no rc8 (mais tarde hoje) e ter
+    uma semana de testes na minha árvore e serem revertidas se causarem
+    problemas, do que vê-las entrar depois do rc8 e então causarem
+    problemas na versão 6.19.
+
+* De `2023-04-20 <https://lore.kernel.org/all/CAHk-=wis_qQy4oDNynNKi5b7Qhosmxtoj1jxo5wmB6SRUwQUBQ@mail.gmail.com/>`_::
+
+    Mas algo como isto, em que a regressão estava na versão anterior e é
+    apenas uma correção clara sem sutileza semântica, considero apenas uma
+    regressão comum que deve ser acelerada - em parte para chegar ao stable,
+    e em parte para evitar ter de colocar a correção em _outro_ kernel
+    stable.
+
+Sobre enviar merge requests com apenas uma correção
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2024-04-24 <https://lore.kernel.org/all/CAHk-=wjy_ph9URuFt-pq+2AJ__p7gFDx=yzVSCsx16xAYvNw9g@mail.gmail.com/>`_::
+
+    Se o problema é apenas não haver mais nada acontecendo, penso que as
+    pessoas deveriam simplesmente me apontar o patch e dizer "pode aplicar
+    esta correção única?"
+
+* De `2023-04-20 <https://lore.kernel.org/all/CAHk-=wis_qQy4oDNynNKi5b7Qhosmxtoj1jxo5wmB6SRUwQUBQ@mail.gmail.com/>`_::
+
+    Estou sempre aberto a correções diretas quando não há controvérsia
+    sobre a correção. Sem problema. Continuo lidando de bom grado com patches
+    individuais.
+
+Sobre apontar relatos de bug com as tags Link:/Closes:
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2025-07-29(1) <https://lore.kernel.org/all/CAHk-=wj2kJRPWx8B09AAtzj+_g+T6UBX11TP0ebs1WJdTtv=WQ@mail.gmail.com/>`_::
+
+    [...] reverter assim, seria realmente bom linkar os problemas, para que
+    quando as pessoas tentarem reabilitar, tenham o histórico de por que não
+    funcionou na primeira vez.
+
+* De `2022-05-08 <https://lore.kernel.org/all/CAHk-=wjMmSZzMJ3Xnskdg4+GGz=5p5p+GSYyFBTh0f-DgvdBWg@mail.gmail.com/>`_::
+
+    Então tenho de reclamar mais uma vez [...]
+
+    [...] Não há link para o problema real que o patch corrige.
+
+* De `2022-06-22 <https://lore.kernel.org/all/CAHk-=wjxzafG-=J8oT30s7upn4RhBs6TX-uVFZ5rME+L5_DoJA@mail.gmail.com/>`_::
+
+    Veja, *aquele* link [para o relato] teria sido útil no commit.
+
+Sobre por que a regra "sem regressões" existe
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-22 <https://lore.kernel.org/all/CAHk-=wheQNiW_WtHGO7bKkT7Uib-p+ai2JP9M+z+FYcZ6CAxYA@mail.gmail.com/>`_::
+
+    Mas a regra básica é: seja tão bom em compatibilidade reversa que os
+    usuários nunca precisem se preocupar em atualizar. Eles devem
+    absolutamente se sentir confiantes de que qualquer problema relatado ao
+    kernel será resolvido ou terá uma solução fácil apropriada para *eles*
+    (ou seja, não se espera que um usuário não técnico consiga fazer muita
+    coisa).
+
+    Porque a última coisa que queremos é gente evitando testar kernels
+    novos.
+
+* De `2024-05-28 <https://lore.kernel.org/all/CAHk-=wgtb7y-bEh7tPDvDWru7ZKQ8-KMjZ53Tsk37zsPPdwXbA@mail.gmail.com/>`_::
+
+    Introduzi essa regra de "sem regressões" há algo como duas décadas,
+    porque as pessoas precisam poder atualizar o seu kernel sem medo de que
+    algo em que confiavam pare de funcionar de repente.
+
+* De `2018-08-03 <https://lore.kernel.org/all/CA+55aFwWZX=CXmWDTkDGb36kf12XmTehmQjbiMPCqCRG2hi9kw@mail.gmail.com/>`_::
+
+    O ponto central de "não causamos regressões" é que as pessoas possam
+    atualizar o kernel e nunca precisarem se preocupar com isso.
+
+    [...]
+
+    Porque a única coisa que importa É O USUÁRIO.
+
+* De `2017-10-26(1) <https://lore.kernel.org/lkml/CA+55aFxW7NMAMvYhkvz1UPbUTUJewRt6Yb51QAx5RtrWOwjebg@mail.gmail.com/>`_::
+
+    Se o kernel funcionava para você, a regra é que ele continua
+    funcionando para você.
+
+    [...]
+
+    As pessoas deveriam basicamente sempre sentir que podem atualizar o seu
+    kernel e simplesmente não precisar se preocupar com isso.
+
+    Eu me recuso a introduzir limitações do tipo "você só pode atualizar o
+    kernel se também atualizar aquele outro programa". Se o kernel
+    funcionava para você, a regra é que ele continua funcionando para você.
+
+Sobre exceções à regra "sem regressões"
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-22 <https://lore.kernel.org/all/CAHk-=wheQNiW_WtHGO7bKkT7Uib-p+ai2JP9M+z+FYcZ6CAxYA@mail.gmail.com/>`_::
+
+    Há _muito_ poucas exceções a essa regra, sendo a principal "o
+    problema era uma questão de segurança fundamental, enorme e gritante, e
+    nós *tivemos* de fazer aquela mudança, e não conseguimos sequer fazer o
+    seu caso de uso limitado continuar funcionando".
+
+    A outra exceção é "o problema foi relatado anos depois de ter sido
+    introduzido, e agora a maioria das pessoas depende do novo
+    comportamento".
+
+    [...]
+
+    Agora, se forem um ou dois usuários e você conseguir simplesmente fazer
+    com que recompilem,
+    isso é uma coisa. Hardware de nicho e casos de uso estranhos às vezes
+    podem ser resolvidos assim, e regressões às vezes podem ser corrigidas
+    orientando cada pessoa que relata, se ela estiver disposta e puder mudar
+    o seu fluxo de trabalho.
+
+* De `2023-04-20 <https://lore.kernel.org/all/CAHk-=wis_qQy4oDNynNKi5b7Qhosmxtoj1jxo5wmB6SRUwQUBQ@mail.gmail.com/>`_::
+
+    E sim, considero "regressão em uma versão anterior" uma regressão que
+    precisa de correção.
+
+    Obviamente há um limite de tempo: se aquela "regressão em uma versão
+    anterior" foi há um ano ou mais, e simplesmente levou uma eternidade
+    para as pessoas notarem, e tinha mudanças semânticas que agora
+    significam que corrigir a regressão poderia causar uma _nova_
+    regressão, então isso pode me levar a dizer "Ah, agora a nova semântica
+    é com o que temos de conviver".
+
+* De `2017-10-26(2) <https://lore.kernel.org/lkml/CA+55aFxW7NMAMvYhkvz1UPbUTUJewRt6Yb51QAx5RtrWOwjebg@mail.gmail.com/>`_::
+
+    Houve exceções, mas são raras, e geralmente têm algum motivo maior e
+    fundamental para terem acontecido, basicamente totalmente inevitável, e
+    as pessoas _tentaram_muito_ evitá-las. Talvez não consigamos mais
+    suportar o hardware, na prática, depois de décadas de idade e de
+    ninguém mais usá-lo com kernels modernos. Talvez haja um problema de
+    segurança sério em como fizemos as coisas, e as pessoas de fato
+    dependiam daquele modelo fundamentalmente quebrado. Talvez tenha havido
+    alguma outra quebra fundamental que simplesmente _tinha_ de ter um dia
+    de virada por razões muito centrais e fundamentais.
+
+Sobre situações em que atualizar algo no espaço de usuário pode resolver
+regressões
+~~~~~~~~~~
+
+* De `2018-08-03 <https://lore.kernel.org/all/CA+55aFwWZX=CXmWDTkDGb36kf12XmTehmQjbiMPCqCRG2hi9kw@mail.gmail.com/>`_::
+
+    E caramba, nós atualizamos o kernel O TEMPO TODO sem atualizar nenhum
+    outro programa. Isso é absolutamente necessário, porque flag days
+    e dependências são terrivelmente ruins.
+
+    E também é necessário simplesmente porque eu, como desenvolvedor do
+    kernel, não atualizo ferramentas aleatórias das quais nem me importo
+    enquanto desenvolvo o kernel, e quero que qualquer um dos meus usuários
+    se sinta seguro fazendo o mesmo.
+
+* De `2017-10-26(3) <https://lore.kernel.org/lkml/CA+55aFxW7NMAMvYhkvz1UPbUTUJewRt6Yb51QAx5RtrWOwjebg@mail.gmail.com/>`_::
+
+    Mas se algo de fato quebrar, então a mudança precisa ser corrigida ou
+    revertida. E ela é corrigida no *kernel*. Não dizendo "bem, corrija o
+    seu espaço de usuário então". Foi uma mudança no kernel que expôs o
+    problema, precisa ser o kernel que corrija isso, porque temos um modelo
+    de "atualizar no lugar". Não temos um "atualizar com espaço de usuário
+    novo".
+
+    E eu vou seriamente me recusar a aceitar código de pessoas que não
+    entendem e não honram esta regra muito simples.
+
+    Esta regra também não vai mudar.
+
+    E sim, eu percebo que o kernel é "especial" nesse aspecto. Tenho
+    orgulho disso.
+
+* De `2017-10-26(4) <https://lore.kernel.org/all/CA+55aFwiiQYJ+YoLKCXjN_beDVfu38mg=Ggg5LFOcqHE8Qi7Zw@mail.gmail.com/>`_::
+
+    Se você quebra configurações de espaço de usuário existentes, ISSO É
+    UMA REGRESSÃO.
+
+    Não é aceitável dizer "mas nós vamos corrigir a configuração do espaço
+    de usuário".
+
+    Sério. NÃO É ACEITÁVEL.
+
+O que qualifica como interface: ABI, API e documentação
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-20 <https://lore.kernel.org/all/CAHk-=wga8Qu0-OSE9VZbviq9GuqwhPhLUXeAt-S7_9+fMCLkKg@mail.gmail.com/>`_::
+
+    Então eu absolutamente detesto toda a noção de "mudanças de ABI". É um
+    conceito sem sentido, e eu o odeio com paixão, [...]
+
+    A regra do Linux para regressões baseia-se basicamente na questão
+    filosófica de "se uma árvore cai na floresta e ninguém está por perto
+    para ouvir, ela faz som?".
+
+    Então a única coisa que importa é se algo quebra comportamento
+    *consciente* do usuário.
+
+    E quando isso acontece, a distinção entre "correção de bug" e "nova
+    funcionalidade" e "mudança de ABI" não importa nem um pouco, e a
+    mudança precisa ser feita de outra forma.
+
+    [...]
+
+    Eu só queria apontar que o argumento sobre ser ou não uma mudança de
+    ABI é irrelevante. Se ocorrer de algum programa - não um script de
+    teste, mas algo relevante para as expectativas conscientes do usuário -
+    depender do comportamento antigo e quebrado, então isso precisa ser
+    feito de outra maneira.
+
+* De `2026-02-13 <https://lore.kernel.org/all/CAHk-=whY-N8kjm8kiFUV5Ei-8AuYw--EPGD-AR3Pd+5GTx2sAQ@mail.gmail.com/>`_::
+
+    > [...] isto não deveria se enquadrar na regra de não quebrar o espaço
+    > de usuário [...]
+
+    Note que a regra é sobre quebrar *usuários*, não quebrar o espaço de
+    usuário em si. [...]
+
+    Se alguma configuração de usuário quebra, as coisas precisam ser
+    corrigidas.
+
+    [...] mas quero deixar muito claro que não há desculpas quanto a
+    "aplicações de espaço de usuário".
+
+* De `2021-09-20(4) <https://lore.kernel.org/all/CAHk-=wi7DB2SJ-wngVvsJ7Ak2cM556Q8437sOXo4EJt2BWPdEg@mail.gmail.com/>`_::
+
+    [...] uma regressão é um pouco como o gato de Schrödinger - se ninguém
+    está por perto para notá-la e ela de fato não afeta nenhuma carga de
+    trabalho real, então você pode tratar a regressão como se não
+    existisse.
+
+* De `2020-05-21 <https://lore.kernel.org/all/CAHk-=wiVi7mSrsMP=fLXQrXK_UimybW=ziLOwSzFTtoXUacWVQ@mail.gmail.com/>`_::
+
+    As regras sobre regressões nunca foram sobre qualquer tipo de
+    comportamento documentado, ou sobre onde o código vive.
+
+    As regras sobre regressões são sempre sobre "quebrar o fluxo de
+    trabalho do usuário".
+
+    Os usuários são literalmente a _única_ coisa que importa.
+
+* De `2019-09-15 <https://lore.kernel.org/lkml/CAHk-=wiP4K8DRJWsCo=20hn_6054xBamGKF2kPgUzpB5aMaofA@mail.gmail.com/>`_::
+
+    Uma reversão _particularmente_ de última hora é o commit mais ao topo
+    (ignorando a mudança de versão em si) feito pouco antes do lançamento,
+    e, embora seja muito chata, é talvez também instrutiva.
+
+    O que é instrutivo nela é que eu reverti um commit que não tinha bug
+    algum. De fato, ele fazia exatamente o que se propunha a fazer, e fazia
+    muito bem. Tão bem que os padrões de E/S muito melhores que ele causou
+    acabaram revelando uma regressão visível ao usuário, devido a um bug
+    real em uma área completamente não relacionada.
+
+    Os detalhes reais dessa regressão, porém, não são o motivo pelo qual
+    aponto aquela reversão como instrutiva. É mais que ela é um exemplo
+    instrutivo do que conta como regressão e do que significa a regra do
+    kernel de "sem regressões".
+
+    [...] O commit revertido não mudou nenhuma API e não introduziu nenhum
+    bug novo. Mas acabou expondo outro problema e, assim, fez uma atualização
+    de kernel falhar para um usuário. Então foi revertido.
+
+    O ponto aqui é que revertemos com base no _comportamento_ relatado pelo
+    usuário, não com base em algum conceito de "isso muda a ABI" ou "isso
+    causou um bug". O problema já existia de fato, e simplesmente não tinha
+    disparado antes. [...]
+
+    Conclusão de tudo isso: não se trata de saber se você muda a ABI entre
+    kernel e espaço de usuário, ou se corrige um bug, ou se o código antigo
+    "nunca deveria ter funcionado". Trata-se de saber se algo quebra o
+    fluxo de trabalho dos usuários existentes.
+
+* De `2017-11-05 <https://lore.kernel.org/all/CA+55aFzUvbGjD8nQ-+3oiMBx14c_6zOj2n7KLN3UsJ-qsd4Dcw@mail.gmail.com/>`_::
+
+    E a nossa regra de regressão nunca foi "o comportamento não muda".
+    Isso significaria que nunca poderíamos fazer mudança alguma.
+
+* De `2020-05-21 <https://lore.kernel.org/all/CAHk-=wiVi7mSrsMP=fLXQrXK_UimybW=ziLOwSzFTtoXUacWVQ@mail.gmail.com/>`_::
+
+    Nenhuma quantidade de "você não deveria ter usado isso" ou "aquele
+    comportamento era indefinido, a culpa é sua por seu aplicativo ter
+    quebrado" ou "aquilo funcionava só por causa de um bug do kernel" é
+    minimamente relevante.
+
+* De `2021-05-21 <https://lore.kernel.org/all/CAHk-=wiVi7mSrsMP=fLXQrXK_UimybW=ziLOwSzFTtoXUacWVQ@mail.gmail.com/>`_::
+
+    Mas não, "estava documentado como quebrado" (seja porque o código
+    estava em staging, seja porque a página de manual dizia outra coisa) é
+    irrelevante. Se o código de staging é tão útil que as pessoas acabam
+    usando, isso significa que ele é basicamente código normal do kernel com
+    uma tag dizendo "por favor, limpe isto".
+
+    [...]
+
+    O outro lado da moeda é que as pessoas que falam em "estabilidade de
+    API" estão totalmente erradas. APIs também não importam. Você pode fazer
+    qualquer mudança em uma API que quiser - desde que ninguém note.
+
+    De novo, a regra de regressão não é sobre documentação, não é sobre
+    APIs e não é sobre a fase da lua.
+
+* De `2012-07-06 <https://lore.kernel.org/all/CA+55aFwnLJ+0sjx92EGREGTWOx84wwKaraSzpTNJwPVV8edw8g@mail.gmail.com/>`_::
+
+    > Agora isso me fez perguntar se o Debian _unstable_ de fato se
+    > qualifica como espaço de usuário de distribuição padrão.
+
+    Ah, se o kernel quebra algum espaço de usuário padrão, isso conta.
+    Muitíssimas pessoas rodam Debian unstable
+
+* De `2011-05-06 <https://lore.kernel.org/all/BANLkTi=KVXjKR82sqsz4gwjr+E0vtqCmvA@mail.gmail.com/>`_::
+
+    Claramente NÃO é um tracepoint interno. Por definição. Ele está sendo
+    usado pelo powertop.
+
+Sobre regressões notadas por usuários ou por suítes de teste/CI
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-22 <https://lore.kernel.org/all/CAHk-=wheQNiW_WtHGO7bKkT7Uib-p+ai2JP9M+z+FYcZ6CAxYA@mail.gmail.com/>`_::
+
+    Usuários reclamando é a única linha real no fim das contas.
+
+    [...] uma suíte de teste reclamando é então frequentemente uma
+    indicação *muito* boa de que talvez os usuários esbarrem em algum
+    problema, e problemas de suíte de teste devem ser levados muito a sério
+    [...]
+
+    Mas um erro de suíte de teste não é necessariamente onde se deve traçar
+    a linha - é um grande sinal de alerta [...]
+
+* De `2024-29-01 <https://lore.kernel.org/all/CAHk-=wg8BrZEzjJ5kUyZzHPZmFqH6ooMN1gRBCofxxCfucgjaw@mail.gmail.com/>`_::
+
+    A regra "sem regressões" não é sobre um "se eu fizer isto, o
+    comportamento muda" inventado.
+
+    A regra "sem regressões" é sobre *usuários*.
+
+    Se você tem um usuário real que vem fazendo coisas insanas, e nós
+    mudamos algo, e agora a coisa insana não funciona mais, nesse ponto é
+    uma regressão, e nós vamos suspirar, dizer "usuários são insanos" e
+    ter de corrigir.
+
+    Mas se você tem algum teste aleatório que agora se comporta de modo
+    diferente, não é uma regressão. É um sinal de *alerta*, claro: testes
+    são úteis.
+
+Sobre aceitar quando uma regressão ocorreu
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2026-01-22 <https://lore.kernel.org/all/CAHk-=wheQNiW_WtHGO7bKkT7Uib-p+ai2JP9M+z+FYcZ6CAxYA@mail.gmail.com/>`_::
+
+    Mas começar a discutir com usuários que relatam mudanças quebradas é
+    basicamente a linha final para mim. Tenho algumas pessoas na minha lista
+    de bloqueio de spam com as quais me recuso a ter qualquer coisa a ver, e
+    em geral foi exatamente por isso.
+
+    Note que não é sobre cometer erros e _causar_ a regressão. Isso é
+    normal. Isso é desenvolvimento. Mas discutir sobre isso é proibido.
+
+* De `2024-06-23 <https://lore.kernel.org/all/CAHk-=wi_KMO_rJ6OCr8mAWBRg-irziM=T9wxGC+J1VVoQb39gw@mail.gmail.com/>`_::
+
+    Nós não introduzimos regressões e depois culpamos os outros.
+
+    Há uma regra muito clara no desenvolvimento do kernel: coisas que
+    quebram outras coisas NÃO SÃO CORREÇÕES.
+
+    NUNCA.
+
+    Elas são revertidas, ou a coisa que quebraram é corrigida.
+
+* De `2021-06-05 <https://lore.kernel.org/all/CAHk-=wiUVqHN76YUwhkjZzwTdjMMJf_zN4+u7vEJjmEGh3recw@mail.gmail.com/>`_::
+
+    NÃO HÁ ARGUMENTOS VÁLIDOS PARA REGRESSÕES.
+
+    Honestamente, as pessoas de segurança precisam entender que "não
+    funcionar" não é um caso de sucesso da segurança. É um caso de falha.
+
+    Sim, "não funcionar" pode ser seguro. Mas segurança, nesse caso, é
+    *inútil*.
+
+* De `2017-10-26(5) <https://lore.kernel.org/lkml/CA+55aFwiiQYJ+YoLKCXjN_beDVfu38mg=Ggg5LFOcqHE8Qi7Zw@mail.gmail.com/>`_::
+
+    [...] quando regressões *de fato* ocorrem, nós as admitimos e as
+    corrigimos, em vez de culpar o espaço de usuário.
+
+    O fato de você aparentemente estar negando a regressão há três semanas
+    significa que eu vou reverter, e vou parar de aceitar pull requests do AppArmor até que as pessoas envolvidas entendam como o desenvolvimento do
+    kernel é feito.
+
+Sobre idas e vindas
+~~~~~~~~~~~~~~~~~~~
+
+* De `2024-05-28 <https://lore.kernel.org/all/CAHk-=wgtb7y-bEh7tPDvDWru7ZKQ8-KMjZ53Tsk37zsPPdwXbA@mail.gmail.com/>`_::
+
+    A regra "sem regressões" é que não introduzimos bugs NOVOS.
+
+    Ela surgiu *literalmente* porque tínhamos uma dança sem fim de
+    "corrigir dois bugs, introduzir um novo", e isso então resultava em um
+    sistema em que você NÃO PODE CONFIAR.
+
+* De `2021-09-20(1) <https://lore.kernel.org/all/CAHk-=wi7DB2SJ-wngVvsJ7Ak2cM556Q8437sOXo4EJt2BWPdEg@mail.gmail.com/>`_::
+
+    E o que torna as regressões especiais é que, na época em que eu não era
+    tão rígido com essas coisas, acabávamos em "situações de gangorra" sem
+    fim, em que alguém corrigia algo, isso quebrava outra coisa, então essa
+    outra coisa quebrava, e nunca se convergia de fato para nada confiável.
+
+* De `2015-08-13 <https://lore.kernel.org/all/CA+55aFxk8-BsiKwr_S-c+4G6wihKPQVMLE34H9wOZpeua6W9+Q@mail.gmail.com/>`_::
+
+    A política estrita de sem regressões começou, na verdade, principalmente
+    em relação a problemas de suspender/retomar, em que o vai e vem de
+    "corrigir uma máquina, quebrar outra" causava problemas sem fim, e
+    significava que não necessariamente fazíamos progresso algum, apenas
+    movendo um problema de lugar.
+
+Sobre mudanças com risco de causar regressões
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2023-06-02 <https://lore.kernel.org/all/CAHk-=wgyAGUMHmQM-5Eb556z5xiHZB7cF05qjrtUH4F7P-1rSA@mail.gmail.com/>`_::
+
+    Então o que penso que você deveria fazer é corrigir o bug direito, com
+    um patch limpo e sem gambiarras malucas. Isso é algo que podemos então
+    aplicar e testar. Sabendo o tempo todo que "é, isto é uma mudança
+    visível, pode ser que tenhamos de revertê-la".
+
+    Se então alguma carga *real* acabar mostrando uma regressão, podemos
+    simplesmente estar ferrados. Nosso comportamento atual pode ter bugs,
+    mas temos a regra de que, uma vez que o espaço de usuário dependa de bugs
+    do kernel, eles se tornam funcionalidades basicamente por definição, por
+    mais que possamos não gostar disso.
+
+Sobre soluções de contorno no kernel para evitar regressões
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2017-10-26(6) <https://lore.kernel.org/lkml/CA+55aFxW7NMAMvYhkvz1UPbUTUJewRt6Yb51QAx5RtrWOwjebg@mail.gmail.com/>`_::
+
+    Mudanças de comportamento acontecem, e talvez não suportemos mais
+    alguma funcionalidade. Há vários campos em /proc/<pid>/stat que são
+    impressos como zeros, simplesmente porque eles nem *existem* mais no
+    kernel, ou porque mostrá-los foi um erro (tipicamente um vazamento de
+    informação). Mas os números foram substituídos por zeros, para que o
+    código que analisava os campos ainda funcione. O usuário pode não ver
+    tudo o que costumava ver, e assim o comportamento é claramente
+    diferente, mas as coisas ainda _funcionam_, mesmo que possam não mostrar
+    mais informações sensíveis (ou não mais relevantes).
+
+Sobre regressões causadas por correções de bug
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2018-08-03 <https://lore.kernel.org/all/CA+55aFwWZX=CXmWDTkDGb36kf12XmTehmQjbiMPCqCRG2hi9kw@mail.gmail.com/>`_::
+
+    > O kernel tinha um bug que foi corrigido
+
+    Isso é *COMPLETAMENTE* irrelevante.
+
+    Gente, se algo tinha bug ou não NÃO IMPORTA.
+
+    [...]
+
+    É basicamente dizer "peguei algo que funcionava, e eu o quebrei, mas
+    agora está melhor". Vocês não veem o quanto essa afirmação é insana?
+
+Sobre mudanças de API internas
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2017-10-26(7) <https://lore.kernel.org/lkml/CA+55aFxW7NMAMvYhkvz1UPbUTUJewRt6Yb51QAx5RtrWOwjebg@mail.gmail.com/>`_::
+
+    Quebramos API _dentro_ do kernel o tempo todo. Corrigimos problemas
+    internos dizendo "agora você precisa fazer XYZ", mas então se trata de
+    APIs internas do kernel, e quem faz isso obviamente também tem de
+    consertar todos os usuários daquela API dentro do kernel. Ninguém pode
+    dizer "eu quebrei a API que você usava, e agora _você_ precisa
+    consertar". Quem quebrou algo também tem de consertar.
+
+Sobre regressões descobertas só depois de muito tempo
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2024-03-28 <https://lore.kernel.org/all/CAHk-=wgFuoHpMk_Z_R3qMXVDgq0N1592+bABkyGjwwSL4zBtHA@mail.gmail.com/>`_::
+
+    Definitivamente não vou reverter um patch de quase uma década atrás
+    como regressão.
+
+    Se levou tanto tempo para descobrir, não pode ser uma regressão tão
+    crítica assim.
+
+    Então sim, vamos tratá-la como um bug comum.
+
+Sobre testar correções de regressão no linux-next
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* No `mantenedores summit 2024 <https://lwn.net/Articles/990599/>`_::
+
+   Então rodar correções pelo linux-next é só uma perda de tempo.
+
+Sobre alguns outros aspectos relacionados a regressões
+~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
+
+* De `2025-07-29(2)
+  <https://lore.kernel.org/all/CAHk-=wjj9DvOZtmTkoLtyfHmy5mNKy6q_96d9=4FUEDXre=cww@mail.gmail.com/>`_
+  [`que não é bem uma regressão, mas um enorme incômodo <https://lore.kernel.org/all/CAHk-=wgO0Rx2LcYT4f75Xs46orbJ4JxO2jbAFQnVKDYAjV5HeQ@mail.gmail.com/>`_]::
+
+    Não tenho mais som.
+
+    Também suspeito que seja puramente porque "make oldconfig" não
+    funciona, e provavelmente desligou minhas configurações antigas do Intel
+    HDA. Ou algo assim.
+
+    Renomear parâmetros de configuração é *ruim*. Tenho batido na tecla de
+    que a fase Kconfig da compilação do kernel é provavelmente o nosso ponto
+    mais desagradável, e um ponto de dor real para quem se envolve com o
+    desenvolvimento, simplesmente porque compilar o próprio kernel pode ser
+    tão intimidador com centenas de perguntas bastante esotéricas.
+
+..
+   fim-do-conteúdo
+..
+   Este texto está disponível sob GPL-2.0+ ou CC-BY-4.0, como declarado
+   no topo do arquivo. Se você quiser distribuir este texto apenas sob
+   CC-BY-4.0, use "The Linux kernel developers" como atribuição de
+   autoria e vincule isto como fonte:
+   https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/plain/Documentation/process/handling-regressions.rst
+..
+   Nota: apenas o conteúdo deste arquivo RST, como encontrado nas fontes
+   do kernel Linux, está disponível sob CC-BY-4.0, pois versões deste
+   texto que foram processadas (por exemplo, pelo sistema de compilação
+   do kernel) podem conter conteúdo retirado de arquivos que usam uma
+   licença mais restritiva.

-- 
2.53.0

