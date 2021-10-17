using Gee;

const string URL_KEY = "url";
const string HITS_KEY = "hits";

const string DATABASE_FILENAME = "hits.csv";
const string TEMP_DATABASE_FILENAME = "temp-hits.csv";
const string PENDING_QUEUE_FILENAME = "pending-hits.csv";

// TODO: Load from another file that is a list of urls. 
// (Represents action queue file that will be used to batch page entry updates
// Every URL in the file should be added to a tally map.
// The tally map values will be added to the page_entries map
// Lastly, the old page entries database will be replaced
// with a new one, reflecting the updated page_entries map data!

int main(string[] args) {
    Map<string, File> required_files = retrieve_required_files ();

    try {
        assert_required_files_exist (required_files);
    } catch (IOError e) {
        error ("Error: %s", e.message);
    }

    Map<string, uint> page_entries = load_page_entries (required_files[DATABASE_FILENAME]);
    print_page_entries (page_entries);

    Iterable<string> pending_hits = load_pending_hits (required_files[PENDING_QUEUE_FILENAME]);
    apply_pending_hits_to (page_entries, pending_hits);

    print ("Updated page entries!\n");
    print_page_entries (page_entries);

    try {
        save_page_entries (page_entries, required_files);
    } catch (Error e) {
        error ("%s", e.message);        
    }

    return 0;
}

void save_page_entries (Map<string, uint> page_entries, Map<string, File> required_files) throws IOError {
    try {
        var save_file = File.new_for_path (TEMP_DATABASE_FILENAME);
       
        // Test for the existence of file
        if (save_file.query_exists ()) {
            save_file.delete();
        }

        var file_stream = save_file.create (FileCreateFlags.REPLACE_DESTINATION);

        // Write data to file
        var data_output_stream = new DataOutputStream (new BufferedOutputStream.sized (file_stream, 65536));
        string text_to_save = generate_page_entries_text (page_entries);

        uint8[] data = text_to_save.data;
        long written = 0;

        while (written < data.length) { 
            // sum of the bytes of 'text' that already have been written to the stream
            written += data_output_stream.write (data[written:data.length]);
        }

        required_files[DATABASE_FILENAME].delete();

        var renamedFile = save_file.set_display_name(DATABASE_FILENAME);
        required_files[DATABASE_FILENAME] = renamedFile;
    } catch (Error e) {
        error ("%s", e.message);
    } 
}

string generate_page_entries_text (Map<string, uint> page_entries) {
    const string header = "url,hits\n";

    StringBuilder string_builder = new StringBuilder();
    string_builder.append (header);

    foreach (var entry in page_entries) {
        string_builder.append_printf ("%s,%u\n", entry.key, entry.value);
    }

    return string_builder.str;
}

void apply_pending_hits_to (Map<string, uint> page_entries, Iterable<string> pending_hits) {
    foreach (string url in pending_hits) {
        page_entries[url] = page_entries.has_key(url) ? 
            page_entries[url] + 1 :
            1;  
    }
}

Iterable<string> load_pending_hits (File pending_hits_file) {
    AbstractCollection<string> pending_hits = new ArrayList<string> ();

    try {
        var data_input_stream = new DataInputStream (pending_hits_file.read ());

        string line;

        while (( line = data_input_stream.read_line (null)) != null) {
            if (line.strip() == "") {
                continue;
            }

            pending_hits.add (line);
        }

        return pending_hits;
    } catch (Error e) {
        error ("%s", e.message);
    }
}

Map<string, uint> load_page_entries (File database_file) {
    try {
        Map<string, uint> page_entries = new HashMap<string, uint> (); 

        // Open file for reading and wrap returned FileInputStream into a
        // DataInputStream, so we can read line by line
        var data_input_stream = new DataInputStream (database_file.read ());

        int url_position = -1;
        int hits_position = -1;

        string line;
        bool is_first_line = true;

        // Read lines until end of file (null) is reached
        while (( line = data_input_stream.read_line (null)) != null) {
            string[] row = line.split(",");

            if (!is_first_line) {
                // Parse each row and add to page hits
                if (url_position < 0  || hits_position < 0) {
                    error ("url and hits keys are not both defined");    
                }

                page_entries[row[url_position]] = uint.parse (row[hits_position]);
                continue;
            }

            for (int i = row.length - 1; i>=0; i--) {
                switch (row[i]) {
                    case URL_KEY:
                    url_position = i;
                    continue;
                    case HITS_KEY:
                    hits_position = i;
                    continue;
                }
            }
            is_first_line = false;
        }

        return page_entries;
    } catch (Error e) {
        error ("%s", e.message);
    }
}

Map<string, File> retrieve_required_files () {
    Map<string, File> required_files = new HashMap<string, File> ();
    required_files[DATABASE_FILENAME] = File.new_for_path (DATABASE_FILENAME);
    required_files[PENDING_QUEUE_FILENAME] = File.new_for_path (PENDING_QUEUE_FILENAME);

    return required_files;
}

void print_page_entries (Map<string, uint> page_entries) {
    foreach (var entry in page_entries){
        print ("Site: %s, Hits: %u\n", entry.key, entry.value);
    }
}

void assert_required_files_exist (Map<string, File> required_files) throws IOError {
    foreach (File file in required_files.values) {
        if (!file.query_exists ()) {
            throw new IOError.NOT_FOUND("Required file not found %s", file.get_path ());
        }
    }
}
