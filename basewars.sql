CREATE TABLE IF NOT EXISTS `basewars` (
  `sid64` varchar(20) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `money` bigint(20) unsigned NOT NULL DEFAULT '0',
  `karma` int(8) NOT NULL DEFAULT '0',
  `time` bigint(20) unsigned NOT NULL DEFAULT '0',
  `xp` int(11) NOT NULL DEFAULT '0',
  `level` int(11) NOT NULL DEFAULT '1',
  PRIMARY KEY (`sid64`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `basewars_textscreen_configs` (
  `sid64` varchar(20) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `config` text NOT NULL,
  PRIMARY KEY (`sid64`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `basewars_crash_refunds` (
  `sid64` varchar(20) CHARACTER SET ascii COLLATE ascii_bin NOT NULL,
  `session_id` varchar(32) NOT NULL,
  `amount` bigint(20) unsigned NOT NULL,
  PRIMARY KEY (`sid64`, `session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
