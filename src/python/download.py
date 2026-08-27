"""Download a table from a MySQL database and save it as a CSV file."""

import argparse
import logging
import os
import sys

import pandas as pd
import yaml
from sqlalchemy import create_engine
from sqlalchemy.engine import URL


def get_arguments():
    """Get the arguments entered on the command line."""
    parser = argparse.ArgumentParser(
        description="Download a table from a MySQL database to a CSV file."
    )

    parser.add_argument(
        "-t",
        "--table",
        required=True,
        help="Name of the table to download from the database.",
    )

    parser.add_argument(
        "-o",
        "--outfile",
        required=True,
        help="Path where the output CSV file should be saved.",
    )

    parser.add_argument(
        "-c",
        "--config",
        required=True,
        help="Path to the YAML file containing database connection settings.",
    )

    parser.add_argument(
        "-f",
        "--force",
        action="store_true",
        help="Delete the output file if it already exists.",
    )

    return parser.parse_args()


def set_up_logging():
    """Display log messages in the console."""
    logging.basicConfig(
        stream=sys.stdout,
        level=logging.INFO,
        format="%(asctime)s - %(levelname)s - %(message)s",
    )


def read_config(config_file):
    """Read the database connection settings from a YAML file."""
    with open(config_file, "r", encoding="utf-8") as file:
        config = yaml.safe_load(file)

    required_settings = [
        "user",
        "password",
        "hostname",
        "port",
        "schema",
    ]

    for setting in required_settings:
        if setting not in config:
            raise ValueError(
                f"The YAML file is missing the '{setting}' setting."
            )

    return config


def connect_to_database(config):
    """Create a connection engine to the MySQL database."""
    database_url = URL.create(
        drivername="mysql+pymysql",
        username=config["user"],
        password=config["password"],
        host=config["hostname"],
        port=int(config["port"]),
        database=config["schema"],
    )

    return create_engine(database_url)


def download_table(engine, table_name, outfile):
    """Download a table from MySQL and save it as a CSV file."""
    logging.info("Downloading table '%s' from the database.", table_name)

    query = f"SELECT * FROM `{table_name}`"

    df = pd.read_sql(query, con=engine)

    logging.info(
        "Successfully downloaded %s rows.",
        f"{len(df):,}",
    )

    logging.info("Saving data to '%s'.", outfile)

    df.to_csv(
        outfile,
        index=False,
        encoding="utf-8",
    )

    logging.info("Download completed successfully.")


def main():
    """Run every step of the download process."""
    arguments = get_arguments()

    set_up_logging()

    engine = None

    try:
        # Step 1: Check whether the output file already exists
        if os.path.exists(arguments.outfile):

            if arguments.force:
                logging.info(
                    "Target file '%s' already exists. "
                    "'--force' was provided, so the existing file will be deleted.",
                    arguments.outfile,
                )

                os.remove(arguments.outfile)

            else:
                logging.info(
                    "The target file '%s' already exists. "
                    "Use -f or --force to overwrite it.",
                    arguments.outfile,
                )

                return 0

        # Step 2: Read database configuration
        logging.info(
            "Reading database settings from '%s'.",
            arguments.config,
        )

        config = read_config(arguments.config)

        # Step 3: Connect to the database
        logging.info("Connecting to the remote database.")

        engine = connect_to_database(config)

        # Step 4: Test the database connection
        with engine.connect() as connection:
            connection.exec_driver_sql("SELECT 1")

        logging.info("Database connection successful.")

        # Step 5: Download the table and save it as a CSV
        download_table(
            engine,
            arguments.table,
            arguments.outfile,
        )

        return 0

    except Exception:
        logging.exception("The download failed.")
        return 1

    finally:
        # Step 6: Close the database connection
        if engine is not None:
            engine.dispose()
            logging.info("Database connection closed.")


if __name__ == "__main__":
    raise SystemExit(main())
