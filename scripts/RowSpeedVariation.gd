class_name RowSpeedVariation
extends PlatformModifier

# Mecanica "speed por linha": cada linha movel sorteia a propria speed em torno da speed do estagio.
# E de linha (o gerador a detecta e aplica na speed antes de preencher_linha); nunca entra na lista de plataforma.


# Fator multiplicativo em [1 - variacao, 1 + variacao]; variacao <= 0 = 1.0 exato, sem consumir o rng.
static func fator(rng: RandomNumberGenerator, variacao: float) -> float:
	if variacao <= 0.0:
		return 1.0
	return rng.randf_range(1.0 - variacao, 1.0 + variacao)


# Linha inicial (garantir_cor_inicial) nunca varia a speed
func vale_em_linha_inicial() -> bool:
	return false
