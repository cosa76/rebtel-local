{# Chemin du fichier Parquet d'un modèle : storage/<couche>/<modèle>.parquet #}
{% macro storage_path(layer) -%}
{{ var('storage_root') }}/{{ layer }}/{{ model.name }}.parquet
{%- endmacro %}
