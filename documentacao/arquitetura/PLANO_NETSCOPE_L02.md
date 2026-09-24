# L-02.1 — evidência local Netscope

Contrato independente de UI, dependente apenas de `NetworkCore`, que projeta
fatos allowlisted de `NetworkMeasurement`. Ausências e valores inválidos são
omitidos; contexto declarado é separado de evidência. Não inclui egress,
segredo, atestação remota, trust tier, quota ou mudança no motor.
