COPY (
    SELECT *
    FROM read_csv_auto(
        'chunks/*.csv',
        files_to_sniff = -1,
        types = {
            'ticket_number': VARCHAR,
            'fine_amount': DOUBLE
        }
    )
)
TO 'parking_raw.csv'
(FORMAT CSV, HEADER, QUOTE '"');
