package io.linka.app.kotlin.ui.screen

import androidx.activity.compose.BackHandler
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.ExitTransition
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Security
import androidx.compose.material.icons.outlined.Speed
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.FilledTonalButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import io.linka.app.kotlin.ui.LkColors
import io.linka.app.kotlin.ui.LkSpacing
import io.linka.app.kotlin.ui.LocalLkTokens
import kotlinx.coroutines.launch

private const val TOTAL_SLIDES = 3

@Composable
fun OnboardingScreen(
    onConcluir: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val c = LocalLkTokens.current
    val pagerState = rememberPagerState(pageCount = { TOTAL_SLIDES })
    val scope = rememberCoroutineScope()
    val alturaTelaDP = LocalConfiguration.current.screenHeightDp
    val iconeSizeDp: Dp = if (alturaTelaDP < 540) 64.dp else 88.dp
    val paginaAtual = pagerState.currentPage

    // Back: slide 0 → consumir sem navegar; slides 1+ → volta ao anterior
    BackHandler {
        if (paginaAtual > 0) {
            scope.launch { pagerState.animateScrollToPage(paginaAtual - 1, animationSpec = tween(200)) }
        }
    }

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(c.bgPrimary),
    ) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize(),
        ) { pagina ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .semantics {
                        contentDescription = "Página ${pagina + 1} de 3, ${when(pagina) { 0 -> "boas-vindas"; 1 -> "privacidade"; else -> "diagnóstico em cores" }}"
                    },
                horizontalAlignment = Alignment.CenterHorizontally,
            ) {
                // Zona ilustração: weight responsivo por altura de tela
                val pesoIlustracao: Float = when {
                    alturaTelaDP < 540 -> 0.35f
                    else -> 0.40f
                }
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(pesoIlustracao),
                    contentAlignment = Alignment.Center,
                ) {
                    when (pagina) {
                        0 -> Icon(
                            imageVector = Icons.Outlined.Speed,
                            contentDescription = "Gauge de velocidade com diagnóstico",
                            tint = LkColors.accent,
                            modifier = Modifier.size(iconeSizeDp),
                        )
                        1 -> Icon(
                            imageVector = Icons.Outlined.Security,
                            contentDescription = "Escudo de privacidade",
                            tint = LkColors.accent,
                            modifier = Modifier.size(iconeSizeDp),
                        )
                        2 -> Row(
                            modifier = Modifier.semantics {
                                contentDescription = "Indicadores de qualidade: verde, amarelo e vermelho"
                            },
                            horizontalArrangement = Arrangement.spacedBy(10.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(20.dp)
                                    .background(LkColors.success, CircleShape),
                            )
                            Box(
                                modifier = Modifier
                                    .size(20.dp)
                                    .background(LkColors.warning, CircleShape),
                            )
                            Box(
                                modifier = Modifier
                                    .size(20.dp)
                                    .background(LkColors.error, CircleShape),
                            )
                        }
                    }
                }

                // Zona título + descrição: weight 0.40
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(0.40f)
                        .padding(horizontal = LkSpacing.xl),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Top,
                ) {
                    val titulo = when (pagina) {
                        0 -> "Sua internet explicada em português"
                        1 -> "Seus dados ficam com você"
                        else -> "Diagnóstico em cores"
                    }
                    val descricao = when (pagina) {
                        0 -> "Não só os números — o linka analisa sua conexão\ne te diz o que está acontecendo e o que fazer."
                        1 -> "Medimos sua rede, não rastreamos você.\nNenhum dado pessoal sai do seu dispositivo."
                        else -> "Verde: tudo certo. Amarelo: atenção.\nVermelho: há um problema.\nO diagnóstico sempre explica o que fazer."
                    }

                    Text(
                        text = titulo,
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        color = c.textPrimary,
                        textAlign = TextAlign.Center,
                    )
                    Spacer(Modifier.height(LkSpacing.md))
                    Text(
                        text = descricao,
                        style = MaterialTheme.typography.bodyLarge,
                        color = c.textSecondary,
                        textAlign = TextAlign.Center,
                    )
                }

                // Zona dots: centralizado entre texto e botões
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = LkSpacing.sm),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    repeat(TOTAL_SLIDES) { index ->
                        val largura: Dp by animateDpAsState(
                            targetValue = if (index == paginaAtual) 22.dp else 8.dp,
                            animationSpec = tween(durationMillis = 200),
                            label = "dot_width_$index",
                        )
                        val dotDesc = if (index == paginaAtual) {
                            "Slide ${index + 1} de 3, selecionado"
                        } else {
                            "Slide ${index + 1} de 3"
                        }
                        Box(
                            modifier = Modifier
                                .width(largura)
                                .height(10.dp)
                                .background(
                                    color = if (index == paginaAtual) {
                                        LkColors.accent
                                    } else {
                                        c.textSecondary.copy(alpha = 0.55f)
                                    },
                                    shape = CircleShape,
                                )
                                .semantics { contentDescription = dotDesc },
                        )
                        if (index < TOTAL_SLIDES - 1) {
                            Spacer(Modifier.width(6.dp))
                        }
                    }
                }

                // Zona botões: altura responsiva por altura de tela
                val alturaZonaBotoes: Dp = when {
                    alturaTelaDP < 540 -> 56.dp
                    else -> 80.dp
                }
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(alturaZonaBotoes)
                        .padding(horizontal = LkSpacing.xl),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically,
                ) {
                    // Botão ← Anterior: oculto no slide 0
                    if (pagina > 0) {
                        OutlinedButton(
                            onClick = {
                                scope.launch { pagerState.animateScrollToPage(pagina - 1, animationSpec = tween(200)) }
                            },
                            modifier = Modifier.semantics {
                                contentDescription = "Voltar ao slide anterior"
                            },
                            colors = ButtonDefaults.outlinedButtonColors(),
                        ) {
                            Text(
                                text = "← Anterior",
                                style = MaterialTheme.typography.bodyMedium,
                            )
                        }
                    } else {
                        // Espaço reservado para manter layout equilibrado
                        Spacer(Modifier.width(1.dp))
                    }

                    // Slide 2: botão "Começar →" com AnimatedVisibility
                    // Slides 0 e 1: botão "Próximo →"
                    if (pagina == TOTAL_SLIDES - 1) {
                        AnimatedVisibility(
                            visible = paginaAtual == TOTAL_SLIDES - 1,
                            enter = fadeIn(tween(300)),
                            exit = ExitTransition.None,
                        ) {
                            Button(
                                onClick = onConcluir,
                                modifier = Modifier.semantics {
                                    contentDescription = "Começar a usar o app"
                                },
                                colors = ButtonDefaults.buttonColors(
                                    containerColor = LkColors.accent,
                                ),
                            ) {
                                Text(
                                    text = "Começar →",
                                    color = LkColors.linkaTextOnDark,
                                    fontWeight = FontWeight.W600,
                                )
                            }
                        }
                    } else {
                        FilledTonalButton(
                            onClick = {
                                scope.launch { pagerState.animateScrollToPage(pagina + 1, animationSpec = tween(200)) }
                            },
                            modifier = Modifier.semantics {
                                contentDescription = "Próximo slide"
                            },
                            colors = ButtonDefaults.filledTonalButtonColors(),
                        ) {
                            Text(
                                text = "Próximo →",
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.W600,
                            )
                        }
                    }
                }
            }
        }

        // Botão Pular: TopEnd overlay, visível apenas nos slides 0 e 1
        if (paginaAtual < TOTAL_SLIDES - 1) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .align(Alignment.TopEnd)
                    .padding(top = LkSpacing.sm, end = LkSpacing.sm),
                contentAlignment = Alignment.TopEnd,
            ) {
                TextButton(
                    onClick = onConcluir,
                    modifier = Modifier.semantics {
                        contentDescription = "Pular tutorial"
                    },
                ) {
                    Text(
                        text = "Pular",
                        color = c.textSecondary,
                        style = MaterialTheme.typography.bodyMedium,
                    )
                }
            }
        }
    }
}
