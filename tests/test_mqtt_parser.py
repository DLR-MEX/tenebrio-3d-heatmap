"""
Pruebas para el parseo de mensajes MQTT /lv.
"""

import pytest

from mqtt_client import parse_lv_message


class TestParseLvMessage:
    def test_valid_temperature_message(self):
        topic = "/v1.6/devices/tenebrios/t1/lv"
        result = parse_lv_message(topic, b"25.4")
        assert result == {"t1": 25.4}

    def test_valid_integer_payload(self):
        topic = "/v1.6/devices/tenebrios/ventilador/lv"
        result = parse_lv_message(topic, b"1")
        assert result == {"ventilador": 1.0}

    def test_valid_exterior_sensor(self):
        topic = "/v1.6/devices/tenebrios/tex/lv"
        result = parse_lv_message(topic, b"32.1")
        assert result == {"tex": 32.1}

    def test_unknown_variable_returns_none(self):
        topic = "/v1.6/devices/tenebrios/unknown_sensor/lv"
        assert parse_lv_message(topic, b"25.0") is None

    def test_malformed_topic_returns_none(self):
        assert parse_lv_message("/bad/topic", b"25.0") is None

    def test_missing_lv_suffix_returns_none(self):
        topic = "/v1.6/devices/tenebrios/t1/last"
        assert parse_lv_message(topic, b"25.0") is None

    def test_non_numeric_payload_returns_none(self):
        topic = "/v1.6/devices/tenebrios/t1/lv"
        assert parse_lv_message(topic, b"not_a_number") is None

    def test_empty_payload_returns_none(self):
        topic = "/v1.6/devices/tenebrios/t1/lv"
        assert parse_lv_message(topic, b"") is None

    def test_whitespace_payload_stripped(self):
        topic = "/v1.6/devices/tenebrios/t2/lv"
        result = parse_lv_message(topic, b"  26.3  ")
        assert result == {"t2": 26.3}

    def test_negative_value_accepted(self):
        topic = "/v1.6/devices/tenebrios/tex/lv"
        result = parse_lv_message(topic, b"-5.2")
        assert result == {"tex": -5.2}

    def test_all_known_labels_accepted(self):
        labels = ["t1", "t2", "t3", "t4", "t5", "tex", "tps", "tpi", "ventilador", "extractor",
                  "h1", "h2", "h3", "h4", "h5", "hum_general", "amoniaco"]
        for label in labels:
            topic = f"/v1.6/devices/tenebrios/{label}/lv"
            result = parse_lv_message(topic, b"1.0")
            assert result == {label: 1.0}, f"Falló para la etiqueta: {label}"
