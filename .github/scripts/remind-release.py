import calendar
from datetime import date, timedelta


def get_fridays(year, month):
    """Return a list of all Fridays in a given month."""
    c = calendar.Calendar()
    return [
        d
        for d in c.itermonthdates(year, month)
        if d.weekday() == calendar.FRIDAY and d.month == month
    ]


def print_release_calendar(year):
    print(f"# Bi-monthly Release Calendar for  {year}\n")
    print(
        "| Month     | Freeze Week  | Merge Friday | Snapshot     | Quarter | Tag     |"
    )
    print(
        "|-----------|--------------|--------------|--------------|-------|---------|"
    )
    for month in range(1, 13):
        fridays = get_fridays(year, month)
        if not fridays:
            continue
        merge1 = fridays[0] if len(fridays) > 0 else None
        snap1 = fridays[1] if len(fridays) > 1 else None
        merge2 = fridays[2] if len(fridays) > 2 else None
        snap2 = fridays[3] if len(fridays) > 3 else None
        freeze1 = merge1 - timedelta(days=7) if merge1 else None
        freeze2 = merge2 - timedelta(days=7) if merge2 else None
        yy = str(year)[-2:]
        m = str(month)
        tag1 = f"{yy}.{m}.1" if merge1 else ""
        tag3 = f"{yy}.{m}.3" if merge2 else ""
        # Print 1st quarter row
        print(
            f"| {calendar.month_abbr[month]:<9} | "
            f"{freeze1.strftime('%Y-%m-%d') if freeze1 else '':<12} | "
            f"{merge1.strftime('%Y-%m-%d') if merge1 else '':<12} | "
            f"{snap1.strftime('%Y-%m-%d') if snap1 else '':<12} | "
            f"{'Q1':<5} | "
            f"{tag1:<7} |"
        )
        # Print 3rd quarter row
        if merge2:
            print(
                f"| {'':<9} | "
                f"{freeze2.strftime('%Y-%m-%d') if freeze2 else '':<12} | "
                f"{merge2.strftime('%Y-%m-%d') if merge2 else '':<12} | "
                f"{snap2.strftime('%Y-%m-%d') if snap2 else '':<12} | "
                f"{'Q3':<5} | "
                f"{tag3:<7} |"
            )


if __name__ == "__main__":
    import sys

    year = int(sys.argv[1]) if len(sys.argv) > 1 else date.today().year
    print_release_calendar(year)
